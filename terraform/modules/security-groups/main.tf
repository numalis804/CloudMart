# Security Groups Module - CloudMart Network Security Layer
# Implements least-privilege access controls for all infrastructure components

# Data source for current region
data "aws_region" "current" {}

# Security Group for Application Load Balancer (ALB)
resource "aws_security_group" "alb" {
  name_prefix = "${var.project_name}-${var.environment}-alb-"
  description = "Security group for Application Load Balancer - allows HTTP/HTTPS from internet"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name      = "${var.project_name}-${var.environment}-alb-sg"
      Component = "load-balancer"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ALB Ingress Rules
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTP from internet"

  from_port   = 80
  to_port     = 80
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"

  tags = {
    Name = "alb-http-ingress"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow HTTPS from internet"

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"

  tags = {
    Name = "alb-https-ingress"
  }
}

# ALB Egress Rule - to EKS nodes
resource "aws_vpc_security_group_egress_rule" "alb_to_eks" {
  security_group_id = aws_security_group.alb.id
  description       = "Allow traffic to EKS node group"

  from_port                    = 0
  to_port                      = 65535
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.eks_nodes.id

  tags = {
    Name = "alb-to-eks-egress"
  }
}

# Security Group for EKS Nodes
resource "aws_security_group" "eks_nodes" {
  name_prefix = "${var.project_name}-${var.environment}-eks-nodes-"
  description = "Security group for EKS worker nodes"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name                                           = "${var.project_name}-${var.environment}-eks-nodes-sg"
      Component                                      = "eks-nodes"
      "kubernetes.io/cluster/${var.project_name}-${var.environment}" = "owned"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# EKS Nodes Ingress - from ALB
resource "aws_vpc_security_group_ingress_rule" "eks_from_alb" {
  security_group_id = aws_security_group.eks_nodes.id
  description       = "Allow traffic from ALB"

  from_port                    = 0
  to_port                      = 65535
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.alb.id

  tags = {
    Name = "eks-from-alb-ingress"
  }
}

# EKS Nodes Ingress - inter-node communication (all protocols, no port specification)
resource "aws_vpc_security_group_ingress_rule" "eks_inter_node" {
  security_group_id = aws_security_group.eks_nodes.id
  description       = "Allow inter-node communication"

  ip_protocol                  = "-1"  # All protocols
  referenced_security_group_id = aws_security_group.eks_nodes.id

  tags = {
    Name = "eks-inter-node-ingress"
  }
}

# EKS Nodes Ingress - from EKS control plane
resource "aws_vpc_security_group_ingress_rule" "eks_from_control_plane" {
  security_group_id = aws_security_group.eks_nodes.id
  description       = "Allow traffic from EKS control plane"

  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.eks_control_plane.id

  tags = {
    Name = "eks-from-control-plane-https"
  }
}

resource "aws_vpc_security_group_ingress_rule" "eks_from_control_plane_kubelet" {
  security_group_id = aws_security_group.eks_nodes.id
  description       = "Allow kubelet traffic from EKS control plane"

  from_port                    = 10250
  to_port                      = 10250
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.eks_control_plane.id

  tags = {
    Name = "eks-from-control-plane-kubelet"
  }
}

# EKS Nodes Egress - all traffic (for pulling images, accessing AWS APIs, etc.)
resource "aws_vpc_security_group_egress_rule" "eks_all" {
  security_group_id = aws_security_group.eks_nodes.id
  description       = "Allow all outbound traffic"

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  tags = {
    Name = "eks-all-egress"
  }
}

# Security Group for EKS Control Plane
resource "aws_security_group" "eks_control_plane" {
  name_prefix = "${var.project_name}-${var.environment}-eks-cp-"
  description = "Security group for EKS control plane"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name      = "${var.project_name}-${var.environment}-eks-control-plane-sg"
      Component = "eks-control-plane"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# EKS Control Plane Ingress - from nodes
resource "aws_vpc_security_group_ingress_rule" "eks_cp_from_nodes" {
  security_group_id = aws_security_group.eks_control_plane.id
  description       = "Allow traffic from EKS nodes"

  from_port                    = 443
  to_port                      = 443
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.eks_nodes.id

  tags = {
    Name = "eks-cp-from-nodes"
  }
}

# EKS Control Plane Egress - to nodes
resource "aws_vpc_security_group_egress_rule" "eks_cp_to_nodes" {
  security_group_id = aws_security_group.eks_control_plane.id
  description       = "Allow traffic to EKS nodes"

  from_port                    = 0
  to_port                      = 65535
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.eks_nodes.id

  tags = {
    Name = "eks-cp-to-nodes-egress"
  }
}

# Security Group for RDS PostgreSQL
resource "aws_security_group" "rds" {
  name_prefix = "${var.project_name}-${var.environment}-rds-"
  description = "Security group for RDS PostgreSQL - allows access from EKS nodes only"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name      = "${var.project_name}-${var.environment}-rds-sg"
      Component = "database"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# RDS Ingress - from EKS nodes only
resource "aws_vpc_security_group_ingress_rule" "rds_from_eks" {
  security_group_id = aws_security_group.rds.id
  description       = "Allow PostgreSQL from EKS nodes"

  from_port                    = 5432
  to_port                      = 5432
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.eks_nodes.id

  tags = {
    Name = "rds-from-eks-ingress"
  }
}

# RDS Egress - not required (RDS doesn't initiate outbound connections)
# But we add it for completeness
resource "aws_vpc_security_group_egress_rule" "rds_no_egress" {
  security_group_id = aws_security_group.rds.id
  description       = "No egress traffic required"

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"

  tags = {
    Name = "rds-minimal-egress"
  }
}

# Security Group for ElastiCache Redis
resource "aws_security_group" "elasticache" {
  name_prefix = "${var.project_name}-${var.environment}-cache-"
  description = "Security group for ElastiCache Redis - allows access from EKS nodes only"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name      = "${var.project_name}-${var.environment}-elasticache-sg"
      Component = "cache"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# ElastiCache Ingress - from EKS nodes only
resource "aws_vpc_security_group_ingress_rule" "elasticache_from_eks" {
  security_group_id = aws_security_group.elasticache.id
  description       = "Allow Redis from EKS nodes"

  from_port                    = 6379
  to_port                      = 6379
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.eks_nodes.id

  tags = {
    Name = "elasticache-from-eks-ingress"
  }
}

# ElastiCache Egress - not required
resource "aws_vpc_security_group_egress_rule" "elasticache_no_egress" {
  security_group_id = aws_security_group.elasticache.id
  description       = "No egress traffic required"

  from_port   = 443
  to_port     = 443
  ip_protocol = "tcp"
  cidr_ipv4   = "0.0.0.0/0"

  tags = {
    Name = "elasticache-minimal-egress"
  }
}

# Optional: Bastion Host Security Group (for administrative access)
resource "aws_security_group" "bastion" {
  count = var.enable_bastion_sg ? 1 : 0

  name_prefix = "${var.project_name}-${var.environment}-bastion-"
  description = "Security group for bastion host - SSH access from specific IPs"
  vpc_id      = var.vpc_id

  tags = merge(
    var.common_tags,
    {
      Name      = "${var.project_name}-${var.environment}-bastion-sg"
      Component = "bastion"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Bastion Ingress - SSH from allowed CIDRs
resource "aws_vpc_security_group_ingress_rule" "bastion_ssh" {
  count = var.enable_bastion_sg && length(var.bastion_allowed_cidrs) > 0 ? length(var.bastion_allowed_cidrs) : 0

  security_group_id = aws_security_group.bastion[0].id
  description       = "Allow SSH from allowed CIDR ${var.bastion_allowed_cidrs[count.index]}"

  from_port   = 22
  to_port     = 22
  ip_protocol = "tcp"
  cidr_ipv4   = var.bastion_allowed_cidrs[count.index]

  tags = {
    Name = "bastion-ssh-ingress-${count.index}"
  }
}

# Bastion Egress - to EKS nodes for administrative access
resource "aws_vpc_security_group_egress_rule" "bastion_to_eks" {
  count = var.enable_bastion_sg ? 1 : 0

  security_group_id = aws_security_group.bastion[0].id
  description       = "Allow SSH to EKS nodes"

  from_port                    = 22
  to_port                      = 22
  ip_protocol                  = "tcp"
  referenced_security_group_id = aws_security_group.eks_nodes.id

  tags = {
    Name = "bastion-to-eks-egress"
  }
}

# Bastion Egress - general internet access
resource "aws_vpc_security_group_egress_rule" "bastion_internet" {
  count = var.enable_bastion_sg ? 1 : 0

  security_group_id = aws_security_group.bastion[0].id
  description       = "Allow internet access"

  ip_protocol = "-1"
  cidr_ipv4   = "0.0.0.0/0"

  tags = {
    Name = "bastion-internet-egress"
  }
}

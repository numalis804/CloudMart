output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "eks_nodes_security_group_id" {
  description = "ID of the EKS nodes security group"
  value       = aws_security_group.eks_nodes.id
}

output "eks_control_plane_security_group_id" {
  description = "ID of the EKS control plane security group"
  value       = aws_security_group.eks_control_plane.id
}

output "rds_security_group_id" {
  description = "ID of the RDS security group"
  value       = aws_security_group.rds.id
}

output "elasticache_security_group_id" {
  description = "ID of the ElastiCache security group"
  value       = aws_security_group.elasticache.id
}

output "bastion_security_group_id" {
  description = "ID of the bastion security group (if enabled)"
  value       = var.enable_bastion_sg ? aws_security_group.bastion[0].id : null
}

output "security_group_summary" {
  description = "Summary of all security groups"
  value = {
    alb = {
      id   = aws_security_group.alb.id
      name = aws_security_group.alb.name
    }
    eks_nodes = {
      id   = aws_security_group.eks_nodes.id
      name = aws_security_group.eks_nodes.name
    }
    eks_control_plane = {
      id   = aws_security_group.eks_control_plane.id
      name = aws_security_group.eks_control_plane.name
    }
    rds = {
      id   = aws_security_group.rds.id
      name = aws_security_group.rds.name
    }
    elasticache = {
      id   = aws_security_group.elasticache.id
      name = aws_security_group.elasticache.name
    }
  }
}

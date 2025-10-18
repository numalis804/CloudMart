# EKS Node Groups Module - CloudMart Worker Nodes
# Creates managed node groups with auto-scaling and proper IAM configuration

# Data sources
data "aws_ami" "eks_optimized" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.cluster_version}-v*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# Launch template for on-demand node group
resource "aws_launch_template" "on_demand" {
  name_prefix = "${var.project_name}-${var.environment}-ondemand-"
  description = "Launch template for on-demand EKS nodes"

  image_id = data.aws_ami.eks_optimized.id

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"  # Enforce IMDSv2
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true
    security_groups             = [var.node_security_group_id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.common_tags,
      {
        Name                                        = "${var.project_name}-${var.environment}-ondemand-node"
        "kubernetes.io/cluster/${var.cluster_name}" = "owned"
        NodeGroup                                   = "on-demand"
        CostCenter                                  = var.cost_center
      }
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      var.common_tags,
      {
        Name       = "${var.project_name}-${var.environment}-ondemand-volume"
        NodeGroup  = "on-demand"
        CostCenter = var.cost_center
      }
    )
  }

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    cluster_name        = var.cluster_name
    cluster_endpoint    = var.cluster_endpoint
    cluster_ca          = var.cluster_certificate_authority_data
    bootstrap_arguments = "--kubelet-extra-args '--node-labels=nodegroup-type=on-demand,instance-lifecycle=on-demand'"
  }))

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-ondemand-lt"
    }
  )
}

# On-Demand Node Group (Primary)
resource "aws_eks_node_group" "on_demand" {
  cluster_name    = var.cluster_name
  node_group_name = "${var.project_name}-${var.environment}-ondemand-v2"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids
  # version         = var.cluster_version
  # do not specify the cluster version if using a launch template

  scaling_config {
    desired_size = var.ondemand_desired_size
    max_size     = var.ondemand_max_size
    min_size     = var.ondemand_min_size
  }

  update_config {
    max_unavailable_percentage = 33
  }

  launch_template {
    id      = aws_launch_template.on_demand.id
    version = aws_launch_template.on_demand.latest_version
  }

  instance_types = var.ondemand_instance_types
  capacity_type  = "ON_DEMAND"

  labels = {
    role             = "general"
    nodegroup-type   = "on-demand"
    instance-lifecycle = "on-demand"
  }

  tags = merge(
    var.common_tags,
    {
      Name                = "${var.project_name}-${var.environment}-ondemand-ng"
      NodeGroupType       = "on-demand"
      CostCenter          = var.cost_center
      "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
      "k8s.io/cluster-autoscaler/enabled"             = "true"
    }
  )

  # Ensure node group is created after cluster is fully ready
  depends_on = [
    aws_launch_template.on_demand
  ]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config[0].desired_size]
  }
}

# Launch template for spot node group (optional)
resource "aws_launch_template" "spot" {
  count = var.enable_spot_node_group ? 1 : 0

  name_prefix = "${var.project_name}-${var.environment}-spot-"
  description = "Launch template for spot EKS nodes"

  image_id = data.aws_ami.eks_optimized.id

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  monitoring {
    enabled = true
  }

  network_interfaces {
    associate_public_ip_address = false
    delete_on_termination       = true
    security_groups             = [var.node_security_group_id]
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge(
      var.common_tags,
      {
        Name                                        = "${var.project_name}-${var.environment}-spot-node"
        "kubernetes.io/cluster/${var.cluster_name}" = "owned"
        NodeGroup                                   = "spot"
        CostCenter                                  = var.cost_center
      }
    )
  }

  tag_specifications {
    resource_type = "volume"
    tags = merge(
      var.common_tags,
      {
        Name       = "${var.project_name}-${var.environment}-spot-volume"
        NodeGroup  = "spot"
        CostCenter = var.cost_center
      }
    )
  }

  user_data = base64encode(templatefile("${path.module}/user-data.sh", {
    cluster_name        = var.cluster_name
    cluster_endpoint    = var.cluster_endpoint
    cluster_ca          = var.cluster_certificate_authority_data
    bootstrap_arguments = "--kubelet-extra-args '--node-labels=nodegroup-type=spot,instance-lifecycle=spot --register-with-taints=spot=true:NoSchedule'"
  }))

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-spot-lt"
    }
  )
}

# Spot Node Group (Optional - for cost optimization)
resource "aws_eks_node_group" "spot" {
  count = var.enable_spot_node_group ? 1 : 0

  cluster_name    = var.cluster_name
  node_group_name = "${var.project_name}-${var.environment}-spot-v2"
  node_role_arn   = var.node_role_arn
  subnet_ids      = var.private_subnet_ids
  # version         = var.cluster_version
  # do not specify the cluster version if using a launch template

  scaling_config {
    desired_size = var.spot_desired_size
    max_size     = var.spot_max_size
    min_size     = var.spot_min_size
  }

  update_config {
    max_unavailable_percentage = 50
  }

  launch_template {
    id      = aws_launch_template.spot[0].id
    version = aws_launch_template.spot[0].latest_version
  }

  instance_types = var.spot_instance_types
  capacity_type  = "SPOT"

  labels = {
    role               = "general"
    nodegroup-type     = "spot"
    instance-lifecycle = "spot"
  }

  # Taint spot nodes so only tolerating pods are scheduled
  taint {
    key    = "spot"
    value  = "true"
    effect = "NO_SCHEDULE"
  }

  tags = merge(
    var.common_tags,
    {
      Name                = "${var.project_name}-${var.environment}-spot-ng"
      NodeGroupType       = "spot"
      CostCenter          = var.cost_center
      "k8s.io/cluster-autoscaler/${var.cluster_name}" = "owned"
      "k8s.io/cluster-autoscaler/enabled"             = "true"
    }
  )

  depends_on = [
    aws_launch_template.spot
  ]

  lifecycle {
    create_before_destroy = true
    ignore_changes        = [scaling_config[0].desired_size]
  }
}

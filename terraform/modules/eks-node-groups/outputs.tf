output "ondemand_node_group_id" {
  description = "On-demand node group ID"
  value       = aws_eks_node_group.on_demand.id
}

output "ondemand_node_group_arn" {
  description = "On-demand node group ARN"
  value       = aws_eks_node_group.on_demand.arn
}

output "ondemand_node_group_status" {
  description = "On-demand node group status"
  value       = aws_eks_node_group.on_demand.status
}

output "spot_node_group_id" {
  description = "Spot node group ID"
  value       = var.enable_spot_node_group ? aws_eks_node_group.spot[0].id : null
}

output "spot_node_group_arn" {
  description = "Spot node group ARN"
  value       = var.enable_spot_node_group ? aws_eks_node_group.spot[0].arn : null
}

output "spot_node_group_status" {
  description = "Spot node group status"
  value       = var.enable_spot_node_group ? aws_eks_node_group.spot[0].status : null
}

output "node_groups_summary" {
  description = "Summary of all node groups"
  value = {
    ondemand = {
      id            = aws_eks_node_group.on_demand.id
      instance_types = var.ondemand_instance_types
      min_size      = var.ondemand_min_size
      max_size      = var.ondemand_max_size
      desired_size  = var.ondemand_desired_size
      capacity_type = "ON_DEMAND"
    }
    spot = var.enable_spot_node_group ? {
      id            = aws_eks_node_group.spot[0].id
      instance_types = var.spot_instance_types
      min_size      = var.spot_min_size
      max_size      = var.spot_max_size
      desired_size  = var.spot_desired_size
      capacity_type = "SPOT"
    } : null
  }
}

# VPC Outputs
output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.vpc.vpc_cidr
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

output "nat_gateway_ips" {
  description = "NAT Gateway public IPs"
  value       = module.vpc.nat_gateway_ips
}

# Security Groups Outputs
output "alb_security_group_id" {
  description = "ALB security group ID"
  value       = module.security_groups.alb_security_group_id
}

output "eks_nodes_security_group_id" {
  description = "EKS nodes security group ID"
  value       = module.security_groups.eks_nodes_security_group_id
}

output "eks_control_plane_security_group_id" {
  description = "EKS control plane security group ID"
  value       = module.security_groups.eks_control_plane_security_group_id
}

output "rds_security_group_id" {
  description = "RDS security group ID"
  value       = module.security_groups.rds_security_group_id
}

output "elasticache_security_group_id" {
  description = "ElastiCache security group ID"
  value       = module.security_groups.elasticache_security_group_id
}

output "security_group_summary" {
  description = "Summary of all security groups"
  value       = module.security_groups.security_group_summary
}

# IAM Outputs
output "eks_cluster_role_arn" {
  description = "EKS cluster role ARN"
  value       = module.iam.eks_cluster_role_arn
}

output "eks_node_group_role_arn" {
  description = "EKS node group role ARN"
  value       = module.iam.eks_node_group_role_arn
}

output "parameter_store_policy_arn" {
  description = "Parameter Store policy ARN"
  value       = module.iam.parameter_store_policy_arn
}

output "secrets_manager_policy_arn" {
  description = "Secrets Manager policy ARN"
  value       = module.iam.secrets_manager_policy_arn
}

output "iam_roles_summary" {
  description = "Summary of all IAM roles"
  value       = module.iam.iam_roles_summary
}

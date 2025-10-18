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

output "aws_region" {
  description = "AWS region"
  value       = var.aws_region
}

# EKS Cluster Outputs
output "eks_cluster_id" {
  description = "EKS cluster name"
  value       = module.eks.cluster_id
}

output "eks_cluster_endpoint" {
  description = "EKS cluster endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_version" {
  description = "EKS cluster Kubernetes version"
  value       = module.eks.cluster_version
}

output "eks_cluster_arn" {
  description = "EKS cluster ARN"
  value       = module.eks.cluster_arn
}

output "eks_oidc_provider_arn" {
  description = "OIDC provider ARN for IRSA"
  value       = module.eks.oidc_provider_arn
}

output "eks_oidc_provider" {
  description = "OIDC provider URL (without https://)"
  value       = module.eks.oidc_provider
}

output "eks_cluster_security_group_id" {
  description = "EKS cluster security group ID"
  value       = module.eks.cluster_security_group_id
}

output "eks_kms_key_arn" {
  description = "KMS key ARN for EKS encryption"
  value       = module.eks.kms_key_arn
}

# EKS Node Groups Outputs
output "ondemand_node_group_id" {
  description = "On-demand node group ID"
  value       = module.eks_node_groups.ondemand_node_group_id
}

output "ondemand_node_group_status" {
  description = "On-demand node group status"
  value       = module.eks_node_groups.ondemand_node_group_status
}

output "spot_node_group_id" {
  description = "Spot node group ID"
  value       = module.eks_node_groups.spot_node_group_id
}

output "node_groups_summary" {
  description = "Summary of all node groups"
  value       = module.eks_node_groups.node_groups_summary
}

# EKS Add-ons Outputs
output "coredns_addon_version" {
  description = "CoreDNS add-on version"
  value       = module.eks_addons.coredns_addon_version
}

output "ebs_csi_driver_addon_version" {
  description = "EBS CSI Driver add-on version"
  value       = module.eks_addons.ebs_csi_driver_addon_version
}

# IRSA Roles
output "frontend_sa_role_arn" {
  description = "Frontend service account role ARN"
  value       = module.eks_addons.frontend_sa_role_arn
}

output "api_sa_role_arn" {
  description = "API service account role ARN"
  value       = module.eks_addons.api_sa_role_arn
}

output "worker_sa_role_arn" {
  description = "Worker service account role ARN"
  value       = module.eks_addons.worker_sa_role_arn
}

output "aws_load_balancer_controller_role_arn" {
  description = "AWS Load Balancer Controller role ARN"
  value       = module.eks_addons.aws_load_balancer_controller_role_arn
}

output "irsa_roles_summary" {
  description = "Summary of all IRSA roles"
  value       = module.eks_addons.irsa_roles_summary
}

# EKS Cluster Role
output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster.arn
}

output "eks_cluster_role_name" {
  description = "Name of the EKS cluster IAM role"
  value       = aws_iam_role.eks_cluster.name
}

# EKS Node Group Role
output "eks_node_group_role_arn" {
  description = "ARN of the EKS node group IAM role"
  value       = aws_iam_role.eks_node_group.arn
}

output "eks_node_group_role_name" {
  description = "Name of the EKS node group IAM role"
  value       = aws_iam_role.eks_node_group.name
}

# Custom Policies
output "cloudwatch_logs_policy_arn" {
  description = "ARN of the CloudWatch Logs policy"
  value       = aws_iam_policy.cloudwatch_logs.arn
}

output "ecr_pull_policy_arn" {
  description = "ARN of the ECR pull policy"
  value       = aws_iam_policy.ecr_pull.arn
}

output "parameter_store_policy_arn" {
  description = "ARN of the Parameter Store policy"
  value       = aws_iam_policy.parameter_store.arn
}

output "secrets_manager_policy_arn" {
  description = "ARN of the Secrets Manager policy"
  value       = aws_iam_policy.secrets_manager.arn
}

# IRSA Service Account Roles
output "frontend_service_account_role_arn" {
  description = "ARN of the frontend service account IAM role"
  value       = var.enable_irsa ? aws_iam_role.frontend_service_account[0].arn : null
}

output "api_service_account_role_arn" {
  description = "ARN of the API service account IAM role"
  value       = var.enable_irsa ? aws_iam_role.api_service_account[0].arn : null
}

output "worker_service_account_role_arn" {
  description = "ARN of the worker service account IAM role"
  value       = var.enable_irsa ? aws_iam_role.worker_service_account[0].arn : null
}

output "aws_load_balancer_controller_role_arn" {
  description = "ARN of the AWS Load Balancer Controller IAM role"
  value       = var.enable_irsa ? aws_iam_role.aws_load_balancer_controller[0].arn : null
}

# Summary
output "iam_roles_summary" {
  description = "Summary of all IAM roles"
  value = {
    eks_cluster = {
      name = aws_iam_role.eks_cluster.name
      arn  = aws_iam_role.eks_cluster.arn
    }
    eks_node_group = {
      name = aws_iam_role.eks_node_group.name
      arn  = aws_iam_role.eks_node_group.arn
    }
    frontend_sa = var.enable_irsa ? {
      name = aws_iam_role.frontend_service_account[0].name
      arn  = aws_iam_role.frontend_service_account[0].arn
    } : null
    api_sa = var.enable_irsa ? {
      name = aws_iam_role.api_service_account[0].name
      arn  = aws_iam_role.api_service_account[0].arn
    } : null
    worker_sa = var.enable_irsa ? {
      name = aws_iam_role.worker_service_account[0].name
      arn  = aws_iam_role.worker_service_account[0].arn
    } : null
    aws_lb_controller = var.enable_irsa ? {
      name = aws_iam_role.aws_load_balancer_controller[0].name
      arn  = aws_iam_role.aws_load_balancer_controller[0].arn
    } : null
  }
}
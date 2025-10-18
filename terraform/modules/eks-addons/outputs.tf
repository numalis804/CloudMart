# EKS Add-ons Outputs
output "coredns_addon_version" {
  description = "CoreDNS add-on version"
  value       = aws_eks_addon.coredns.addon_version
}

output "ebs_csi_driver_addon_version" {
  description = "EBS CSI Driver add-on version"
  value       = aws_eks_addon.ebs_csi_driver.addon_version
}

# IRSA Roles Outputs
output "ebs_csi_driver_role_arn" {
  description = "EBS CSI Driver IAM role ARN"
  value       = aws_iam_role.ebs_csi_driver.arn
}

output "frontend_sa_role_arn" {
  description = "Frontend service account IAM role ARN"
  value       = aws_iam_role.frontend_sa.arn
}

output "api_sa_role_arn" {
  description = "API service account IAM role ARN"
  value       = aws_iam_role.api_sa.arn
}

output "worker_sa_role_arn" {
  description = "Worker service account IAM role ARN"
  value       = aws_iam_role.worker_sa.arn
}

output "aws_load_balancer_controller_role_arn" {
  description = "AWS Load Balancer Controller IAM role ARN"
  value       = aws_iam_role.aws_load_balancer_controller.arn
}

output "cluster_autoscaler_role_arn" {
  description = "Cluster Autoscaler IAM role ARN"
  value       = var.enable_cluster_autoscaler ? aws_iam_role.cluster_autoscaler[0].arn : null
}

output "irsa_roles_summary" {
  description = "Summary of all IRSA roles"
  value = {
    ebs_csi_driver = {
      role_arn           = aws_iam_role.ebs_csi_driver.arn
      service_account    = "ebs-csi-controller-sa"
      namespace          = "kube-system"
    }
    frontend = {
      role_arn        = aws_iam_role.frontend_sa.arn
      service_account = "cloudmart-frontend-sa"
      namespace       = var.kubernetes_namespace
    }
    api = {
      role_arn        = aws_iam_role.api_sa.arn
      service_account = "cloudmart-api-sa"
      namespace       = var.kubernetes_namespace
    }
    worker = {
      role_arn        = aws_iam_role.worker_sa.arn
      service_account = "cloudmart-worker-sa"
      namespace       = var.kubernetes_namespace
    }
    aws_load_balancer_controller = {
      role_arn        = aws_iam_role.aws_load_balancer_controller.arn
      service_account = "aws-load-balancer-controller"
      namespace       = "kube-system"
    }
  }
}
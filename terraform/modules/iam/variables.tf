variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

variable "enable_irsa" {
  description = "Enable IAM Roles for Service Accounts (IRSA)"
  type        = bool
  default     = false
}

variable "eks_oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider"
  type        = string
  default     = ""
}

variable "eks_oidc_provider" {
  description = "OIDC provider URL (without https://)"
  type        = string
  default     = ""
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace for service accounts"
  type        = string
  default     = "default"
}

variable "enable_sqs_access" {
  description = "Enable SQS access for worker service account"
  type        = bool
  default     = false
}
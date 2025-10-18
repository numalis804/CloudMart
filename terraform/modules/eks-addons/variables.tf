variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  type        = string
}

variable "oidc_provider" {
  description = "OIDC provider URL (without https://)"
  type        = string
}

variable "kubernetes_namespace" {
  description = "Kubernetes namespace for CloudMart applications"
  type        = string
  default     = "cloudmart-dev"
}

variable "parameter_store_policy_arn" {
  description = "ARN of Parameter Store policy"
  type        = string
}

variable "secrets_manager_policy_arn" {
  description = "ARN of Secrets Manager policy"
  type        = string
}

variable "enable_cluster_autoscaler" {
  description = "Enable Cluster Autoscaler"
  type        = bool
  default     = false
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
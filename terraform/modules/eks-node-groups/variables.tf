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

variable "cluster_version" {
  description = "Kubernetes version"
  type        = string
}

variable "cluster_endpoint" {
  description = "EKS cluster endpoint"
  type        = string
}

variable "cluster_certificate_authority_data" {
  description = "EKS cluster certificate authority data"
  type        = string
  sensitive   = true
}

variable "node_role_arn" {
  description = "IAM role ARN for node groups"
  type        = string
}

variable "node_security_group_id" {
  description = "Security group ID for worker nodes"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for node groups"
  type        = list(string)
}

# On-Demand Node Group Configuration
variable "ondemand_instance_types" {
  description = "Instance types for on-demand node group"
  type        = list(string)
  default     = ["t3.small"]
}

variable "ondemand_min_size" {
  description = "Minimum number of on-demand nodes"
  type        = number
  default     = 2
}

variable "ondemand_max_size" {
  description = "Maximum number of on-demand nodes"
  type        = number
  default     = 5
}

variable "ondemand_desired_size" {
  description = "Desired number of on-demand nodes"
  type        = number
  default     = 2
}

# Spot Node Group Configuration
variable "enable_spot_node_group" {
  description = "Enable spot node group"
  type        = bool
  default     = true
}

variable "spot_instance_types" {
  description = "Instance types for spot node group"
  type        = list(string)
  default     = ["t3.micro", "t3.small", "t4g.micro"]
}

variable "spot_min_size" {
  description = "Minimum number of spot nodes"
  type        = number
  default     = 0
}

variable "spot_max_size" {
  description = "Maximum number of spot nodes"
  type        = number
  default     = 3
}

variable "spot_desired_size" {
  description = "Desired number of spot nodes"
  type        = number
  default     = 0
}

variable "cost_center" {
  description = "Cost center tag for billing allocation"
  type        = string
  default     = "CloudMart-Development"
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}

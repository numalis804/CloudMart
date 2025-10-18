variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "cloudmart"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
}

variable "common_tags" {
  description = "Common tags"
  type        = map(string)
  default = {
    Project   = "CloudMart"
    ManagedBy = "Terraform"
  }
}

# EKS Configuration
variable "eks_cluster_version" {
  description = "Kubernetes version for EKS cluster"
  type        = string
  default     = "1.31"
}

# Node Groups Configuration
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

variable "enable_spot_node_group" {
  description = "Enable spot node group for cost optimization"
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

# Cluster Autoscaler
variable "enable_cluster_autoscaler" {
  description = "Enable Cluster Autoscaler"
  type        = bool
  default     = false
}

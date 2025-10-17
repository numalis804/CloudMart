variable "aws_region" {
  description = "AWS region for backend resources"
  type        = string
  default     = "eu-central-1"
}

variable "state_bucket_name" {
  description = "Name of S3 bucket for Terraform state (must be globally unique)"
  type        = string
  default     = "cloudmart-terraform-state-804"
}

variable "lock_table_name" {
  description = "Name of DynamoDB table for state locking"
  type        = string
  default     = "cloudmart-terraform-lock"
}

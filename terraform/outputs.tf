# Global Outputs for CloudMart Infrastructure
# These outputs can be referenced by other modules and configurations

output "aws_region" {
  description = "AWS region where resources are deployed"
  value       = var.aws_region
}

output "environment" {
  description = "Current environment"
  value       = var.environment
}

output "project_name" {
  description = "Project name"
  value       = var.project_name
}

output "common_tags" {
  description = "Common tags applied to all resources"
  value       = var.common_tags
}

# Terraform Backend Configuration
# This file configures remote state storage in S3 with state locking
# 
# Note: This configuration is shared across all environments
# Each environment will use a different state file key

terraform {
  backend "s3" {
    bucket  = "cloudmart-terraform-state-804"
    key     = "base/terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true

    # State locking with DynamoDB
    # Note: use_lockfile is now the preferred method, but for compatibility
    # with S3 backend, we use the DynamoDB table approach
    dynamodb_table = "cloudmart-terraform-lock"
  }
}

# Terraform Backend Configuration
# This file configures remote state storage in S3 with DynamoDB locking
# 
# Note: This configuration is shared across all environments
# Each environment will use a different state file key

terraform {
  backend "s3" {
    bucket         = "cloudmart-terraform-state-804"
    key            = "base/terraform.tfstate"
    region         = "eu-central-1"
    dynamodb_table = "cloudmart-terraform-lock"
    encrypt        = true

    # Enable state locking
    # The DynamoDB table must have a primary key named "LockID"
  }
}

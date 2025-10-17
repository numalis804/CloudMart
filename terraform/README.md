# CloudMart Terraform Infrastructure

This directory contains Infrastructure as Code (IaC) for the CloudMart project using Terraform.

## Directory Structure
```
terraform/
├── backend/          # Backend infrastructure (S3 + DynamoDB)
├── modules/          # Reusable Terraform modules
├── environments/     # Environment-specific configurations
│   ├── dev/
│   ├── staging/
│   └── prod/
├── backend.tf        # Remote state configuration
├── provider.tf       # Provider configurations
├── variables.tf      # Global variables
└── outputs.tf        # Global outputs
```

## Backend Configuration

Terraform state is stored remotely in S3 with DynamoDB for state locking:

- **S3 Bucket:** `cloudmart-terraform-state-804`
- **DynamoDB Table:** `cloudmart-terraform-lock`
- **Region:** `eu-central-1`

## Usage

### Initialize Backend (First Time Only)
```bash
cd terraform/backend
terraform init
terraform apply
```

### Working with Environments
```bash
# Development environment
cd terraform/environments/dev
terraform init
terraform plan
terraform apply

# Staging environment
cd terraform/environments/staging
terraform init
terraform plan
terraform apply
```

## Important Notes

1. **Backend Bootstrap:** The `backend/` directory uses local state to create the remote backend infrastructure
2. **State Locking:** Always ensure your Terraform operations complete to avoid state lock issues
3. **State File Keys:** Each environment uses a different state file key in S3
4. **Versioning:** S3 versioning is enabled for state file history
5. **Encryption:** All state files are encrypted at rest using AES256

## Migrating to Remote Backend

After creating the backend infrastructure, add this to your Terraform configuration:
```hcl
terraform {
  backend "s3" {
    bucket         = "cloudmart-terraform-state-804"
    key            = "environment/terraform.tfstate"  # Change per environment
    region         = "eu-central-1"
    dynamodb_table = "cloudmart-terraform-lock"
    encrypt        = true
  }
}
```

Then run:
```bash
terraform init -migrate-state
```

## Security Considerations

- State files may contain sensitive data
- S3 bucket has versioning and encryption enabled
- Public access is blocked on the state bucket
- DynamoDB table uses encryption at rest
- Point-in-time recovery enabled for DynamoDB

## Cost Optimization

- DynamoDB uses PAY_PER_REQUEST billing mode (no idle costs)
- S3 lifecycle policies expire old state versions after 90 days
- Incomplete multipart uploads are automatically cleaned up

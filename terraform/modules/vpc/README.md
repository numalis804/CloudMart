# VPC Module

This module creates a production-ready VPC with multi-AZ architecture for the CloudMart project.

## Features

- Multi-AZ deployment across 3 availability zones
- Public subnets with Internet Gateway access
- Private subnets with NAT Gateway for outbound connectivity
- Network ACLs for additional security layer
- VPC Flow Logs for monitoring and troubleshooting
- Kubernetes-ready subnet tagging for EKS
- Cost-optimized NAT Gateway configuration (single NAT option)

## Architecture
```
Internet
    |
    v
Internet Gateway
    |
    v
+-- Public Subnets (Multi-AZ) --+
|  - Web tier                    |
|  - Load balancers              |
|  - Bastion hosts               |
+---------------------------------+
    |
    v
NAT Gateway(s)
    |
    v
+-- Private Subnets (Multi-AZ) -+
|  - Application tier            |
|  - EKS worker nodes            |
|  - Database tier               |
+---------------------------------+
```

## Usage
```hcl
module "vpc" {
  source = "../../modules/vpc"

  project_name       = "cloudmart"
  environment        = "dev"
  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
  
  enable_nat_gateway  = true
  single_nat_gateway  = true  # Use false for HA (one NAT per AZ)
  enable_flow_logs    = true

  common_tags = {
    Project   = "CloudMart"
    ManagedBy = "Terraform"
  }
}
```

## Cost Considerations

**Single NAT Gateway (default):**
- Cost: ~$32/month + data transfer
- Use case: Development and staging environments

**NAT Gateway per AZ:**
- Cost: ~$96/month + data transfer (3 AZs)
- Use case: Production environments requiring high availability

Set `single_nat_gateway = false` for production HA configuration.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Name of the project | string | n/a | yes |
| environment | Environment name | string | n/a | yes |
| vpc_cidr | CIDR block for VPC | string | "10.0.0.0/16" | no |
| availability_zones | List of AZs | list(string) | n/a | yes |
| enable_nat_gateway | Enable NAT Gateway | bool | true | no |
| single_nat_gateway | Use single NAT (cost optimization) | bool | true | no |
| enable_flow_logs | Enable VPC Flow Logs | bool | true | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | ID of the VPC |
| public_subnet_ids | List of public subnet IDs |
| private_subnet_ids | List of private subnet IDs |
| nat_gateway_ips | List of NAT Gateway public IPs |

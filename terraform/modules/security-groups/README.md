# Security Groups Module

This module creates a comprehensive set of security groups implementing least-privilege access controls for CloudMart infrastructure components.

## Security Architecture
```
Internet
   ↓ (80, 443)
┌──────────────┐
│     ALB      │ (Public-facing)
└──────────────┘
   ↓ (All TCP)
┌──────────────┐
│  EKS Nodes   │ (Application tier)
└──────────────┘
   ↓ (5432)    ↓ (6379)
┌─────────┐  ┌────────────┐
│   RDS   │  │ElastiCache │ (Data tier)
└─────────┘  └────────────┘
```

## Security Groups

### 1. ALB Security Group
**Purpose:** Public-facing load balancer
- **Ingress:** HTTP (80), HTTPS (443) from internet (0.0.0.0/0)
- **Egress:** All TCP to EKS nodes security group

### 2. EKS Nodes Security Group
**Purpose:** Kubernetes worker nodes running application containers
- **Ingress:** 
  - All TCP from ALB security group
  - All protocols from same security group (inter-node communication)
  - HTTPS (443) from EKS control plane (API communication)
  - Kubelet (10250) from EKS control plane
- **Egress:** All traffic (for image pulls, AWS API access, external dependencies)

### 3. EKS Control Plane Security Group
**Purpose:** Managed EKS control plane
- **Ingress:** HTTPS (443) from EKS nodes
- **Egress:** All TCP to EKS nodes (for kubelet communication)

### 4. RDS Security Group
**Purpose:** PostgreSQL database
- **Ingress:** PostgreSQL (5432) from EKS nodes only
- **Egress:** Minimal (HTTPS for AWS services)

### 5. ElastiCache Security Group
**Purpose:** Redis cache cluster
- **Ingress:** Redis (6379) from EKS nodes only
- **Egress:** Minimal (HTTPS for AWS services)

### 6. Bastion Security Group (Optional)
**Purpose:** Administrative access to private resources
- **Ingress:** SSH (22) from specific allowed CIDR blocks
- **Egress:** SSH to EKS nodes, general internet access

## Usage
```hcl
module "security_groups" {
  source = "../../modules/security-groups"

  project_name = "cloudmart"
  environment  = "dev"
  vpc_id       = module.vpc.vpc_id

  # Optional bastion host
  enable_bastion_sg      = true
  bastion_allowed_cidrs  = ["203.0.113.0/24"]  # Replace with your IP

  common_tags = {
    Project   = "CloudMart"
    ManagedBy = "Terraform"
  }
}
```

## Security Best Practices

1. **Least Privilege:** Each security group only allows the minimum required access
2. **Defense in Depth:** Multiple layers of security (NACLs + Security Groups)
3. **Zero Trust:** Internal resources (RDS, ElastiCache) are not accessible from internet
4. **Segmentation:** Clear separation between tiers (public, application, data)
5. **Auditable:** All rules are documented and version-controlled

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Project name | string | n/a | yes |
| environment | Environment name | string | n/a | yes |
| vpc_id | VPC ID | string | n/a | yes |
| enable_bastion_sg | Enable bastion SG | bool | false | no |
| bastion_allowed_cidrs | Allowed CIDRs for bastion | list(string) | [] | no |

## Outputs

| Name | Description |
|------|-------------|
| alb_security_group_id | ALB security group ID |
| eks_nodes_security_group_id | EKS nodes security group ID |
| eks_control_plane_security_group_id | EKS control plane security group ID |
| rds_security_group_id | RDS security group ID |
| elasticache_security_group_id | ElastiCache security group ID |

## Cost Impact

Security groups themselves have no cost. They are a free AWS service.

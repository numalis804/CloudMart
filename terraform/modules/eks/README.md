# EKS Cluster Module

This module creates a production-ready Amazon EKS cluster with encryption, logging, and OIDC provider.

## Features

- **EKS Cluster:** Kubernetes 1.28+ with configurable endpoints
- **Encryption:** KMS encryption for Kubernetes secrets with automatic key rotation
- **Logging:** Comprehensive control plane logging (API, audit, authenticator, etc.)
- **OIDC Provider:** Enables IAM Roles for Service Accounts (IRSA)
- **Basic Add-ons:** VPC CNI and kube-proxy (CoreDNS added after node groups)
- **Security:** Private/public endpoint configuration with CIDR restrictions

## Important Notes

**Add-ons Deployment Strategy:**
- ✅ VPC CNI and kube-proxy deployed with cluster
- ⏸️ CoreDNS requires worker nodes - deployed in Step 2.3
- ⏸️ EBS CSI Driver requires worker nodes - deployed in Step 2.3

**IRSA (IAM Roles for Service Accounts):**
- ✅ OIDC provider created with cluster
- ⏸️ Service account IAM roles created in Step 2.3 after node groups

This approach avoids:
- CoreDNS timeout issues (needs nodes)
- Circular dependency issues (IAM ↔ EKS)

## Usage
```hcl
module "eks" {
  source = "../../modules/eks"

  project_name = "cloudmart"
  environment  = "dev"
  
  cluster_version  = "1.28"
  cluster_role_arn = module.iam.eks_cluster_role_arn
  
  private_subnet_ids        = module.vpc.private_subnet_ids
  public_subnet_ids         = module.vpc.public_subnet_ids
  cluster_security_group_id = module.security_groups.eks_control_plane_security_group_id
  
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  
  common_tags = {
    Project   = "CloudMart"
    ManagedBy = "Terraform"
  }
}
```

## Cost Impact

**Monthly costs:**
- EKS Control Plane: $73/month
- KMS Key: $1/month
- CloudWatch Logs: ~$1/month
- **Total:** ~$75/month (worker nodes not included)

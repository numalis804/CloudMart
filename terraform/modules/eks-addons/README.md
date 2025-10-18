# EKS Add-ons Module

This module deploys essential EKS add-ons and creates IRSA roles for infrastructure and application workloads.

## Features

### EKS Managed Add-ons
- **CoreDNS:** DNS resolution for Kubernetes services
- **EBS CSI Driver:** Persistent volume support with IRSA

### IRSA Roles Created
- **EBS CSI Driver:** Manages EBS volumes for persistent storage
- **Frontend:** CloudWatch Logs access for frontend pods
- **API:** Parameter Store, Secrets Manager, CloudWatch Logs for API pods
- **Worker:** Parameter Store, Secrets Manager, CloudWatch Logs, SES for worker pods
- **AWS Load Balancer Controller:** Full ALB/NLB management permissions
- **Cluster Autoscaler (Optional):** Auto-scaling group management

## Usage
```hcl
module "eks_addons" {
  source = "../../modules/eks-addons"

  project_name = "cloudmart"
  environment  = "dev"
  cluster_name = module.eks.cluster_id
  
  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider     = module.eks.oidc_provider
  
  parameter_store_policy_arn  = module.iam.parameter_store_policy_arn
  secrets_manager_policy_arn  = module.iam.secrets_manager_policy_arn
  
  kubernetes_namespace = "cloudmart-dev"
  
  enable_cluster_autoscaler = false
  
  common_tags = {
    Project   = "CloudMart"
    ManagedBy = "Terraform"
  }
}
```

## Post-Deployment Steps

After Terraform creates the IRSA roles, deploy Kubernetes components:

1. **AWS Load Balancer Controller** (Helm)
2. **Metrics Server** (kubectl apply)
3. **Cluster Autoscaler** (Optional, Helm)
4. **Kubernetes Service Accounts** (kubectl apply)

See deployment scripts in `~/GitHub/CloudMart/scripts/
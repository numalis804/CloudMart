# IAM Module

This module creates IAM roles and policies for EKS cluster, worker nodes, and application workloads using IRSA (IAM Roles for Service Accounts).

## Features

- **EKS Cluster Role:** IAM role for EKS control plane with required AWS managed policies
- **EKS Node Group Role:** IAM role for worker nodes with ECR, CloudWatch, SSM access
- **Custom Policies:** CloudWatch Logs, ECR Pull, Parameter Store, Secrets Manager access
- **IRSA Support:** IAM roles for Kubernetes service accounts via OIDC provider
- **Service Account Roles:** Frontend, API, Worker microservices with least-privilege access
- **AWS Load Balancer Controller Role:** Comprehensive permissions for ALB/NLB management

## IRSA (IAM Roles for Service Accounts)

IRSA allows Kubernetes pods to assume IAM roles without using node instance profiles. This provides:

- **Least Privilege:** Each pod has only the permissions it needs
- **Credential Isolation:** No shared credentials between pods
- **Audit Trail:** CloudTrail logs show which pod made which API call
- **Dynamic Credentials:** Temporary credentials that automatically rotate

### How IRSA Works
```
┌─────────────────┐
│ Kubernetes Pod  │
│   (Frontend)    │
└────────┬────────┘
         │ 1. Request AWS credentials
         │
         ▼
┌─────────────────────────┐
│  Service Account Token  │
│  (Kubernetes JWT)       │
└────────┬────────────────┘
         │ 2. Exchange token for AWS credentials
         │
         ▼
┌─────────────────────────┐
│   EKS OIDC Provider     │
│   (AWS STS)             │
└────────┬────────────────┘
         │ 3. Return temporary credentials
         │
         ▼
┌─────────────────────────┐
│  IAM Role Assumed       │
│  (frontend-sa-role)     │
└─────────────────────────┘
```

## Service Account Roles

### Frontend Service Account
**Permissions:** CloudWatch Logs (write only)
```yaml
# Kubernetes manifest
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cloudmart-frontend-sa
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT:role/cloudmart-dev-frontend-sa-role
```

### API Service Account
**Permissions:** Parameter Store (read), Secrets Manager (read), CloudWatch Logs (write)
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cloudmart-api-sa
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT:role/cloudmart-dev-api-sa-role
```

### Worker Service Account
**Permissions:** Parameter Store, Secrets Manager, CloudWatch Logs, SES (email), SQS (optional)
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cloudmart-worker-sa
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::ACCOUNT:role/cloudmart-dev-worker-sa-role
```

## Usage
```hcl
module "iam" {
  source = "../../modules/iam"

  project_name = "cloudmart"
  environment  = "dev"

  # Enable IRSA after EKS cluster is created
  enable_irsa             = true
  eks_oidc_provider_arn   = "arn:aws:iam::123456789012:oidc-provider/oidc.eks..."
  eks_oidc_provider       = "oidc.eks.eu-central-1.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
  kubernetes_namespace    = "cloudmart-prod"

  common_tags = {
    Project   = "CloudMart"
    ManagedBy = "Terraform"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Project name | string | n/a | yes |
| environment | Environment name | string | n/a | yes |
| enable_irsa | Enable IRSA | bool | false | no |
| eks_oidc_provider_arn | OIDC provider ARN | string | "" | no |
| eks_oidc_provider | OIDC provider URL | string | "" | no |
| kubernetes_namespace | K8s namespace | string | "default" | no |

## Outputs

| Name | Description |
|------|-------------|
| eks_cluster_role_arn | EKS cluster role ARN |
| eks_node_group_role_arn | EKS node group role ARN |
| frontend_service_account_role_arn | Frontend SA role ARN |
| api_service_account_role_arn | API SA role ARN |
| worker_service_account_role_arn | Worker SA role ARN |

## Security Best Practices

1. **Least Privilege:** Each role has minimum required permissions
2. **Resource Scoping:** Policies scope resources by project/environment
3. **IRSA Over Node Roles:** Use service account roles instead of node instance profiles
4. **Condition Keys:** Trust policies include strict conditions
5. **Managed Policies:** Use AWS managed policies where appropriate
6. **Regular Audits:** Review IAM Access Analyzer findings

## Cost Impact

IAM roles and policies have no direct cost. They are free AWS resources.
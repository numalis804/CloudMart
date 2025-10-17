# CloudMart IAM Roles and Policies Documentation

## Overview

This document provides comprehensive documentation of all IAM roles, policies, and service accounts implemented in the CloudMart infrastructure.

**Last Updated:** $(date +"%Y-%m-%d")

---

## IAM Architecture

### Design Principles

1. **Least Privilege:** Each role has minimum permissions required
2. **Separation of Duties:** Distinct roles for different components
3. **Resource Scoping:** Policies limited to specific resources when possible
4. **IRSA (IAM Roles for Service Accounts):** Pod-level IAM roles via OIDC
5. **Audit Trail:** CloudTrail logs all IAM role assumptions

### Architecture Diagram
```
┌─────────────────────────────────────────────────────────────┐
│                     AWS Account                              │
│                                                              │
│  ┌────────────────┐         ┌──────────────────────────┐   │
│  │ EKS Cluster    │◄────────│ EKS Cluster Role         │   │
│  │                │         │ (Control Plane)          │   │
│  └────────┬───────┘         └──────────────────────────┘   │
│           │                                                  │
│           │                                                  │
│  ┌────────▼───────┐         ┌──────────────────────────┐   │
│  │ EKS Nodes      │◄────────│ EKS Node Group Role      │   │
│  │ (EC2 Workers)  │         │ + Custom Policies        │   │
│  └────────┬───────┘         └──────────────────────────┘   │
│           │                                                  │
│           │  ┌─────────────────────────────────────────┐   │
│           │  │        OIDC Provider                     │   │
│           │  │  (Trust Relationship)                    │   │
│           │  └─────────────────────────────────────────┘   │
│           │                  │                              │
│  ┌────────▼──────────────────▼──────────────────────────┐  │
│  │                Kubernetes Pods                        │  │
│  │                                                       │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐             │  │
│  │  │Frontend │  │   API   │  │ Worker  │             │  │
│  │  │   SA    │  │   SA    │  │   SA    │             │  │
│  │  └────┬────┘  └────┬────┘  └────┬────┘             │  │
│  │       │            │            │                   │  │
│  │       ▼            ▼            ▼                   │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐             │  │
│  │  │Frontend │  │   API   │  │ Worker  │             │  │
│  │  │  Role   │  │  Role   │  │  Role   │             │  │
│  │  └─────────┘  └─────────┘  └─────────┘             │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

---

## IAM Roles Inventory

### 1. EKS Cluster Role

**Role Name:** `cloudmart-dev-eks-cluster-role`

**Purpose:** IAM role for EKS control plane to manage AWS resources

**Assumed By:** `eks.amazonaws.com` service

**Attached Managed Policies:**
- `AmazonEKSClusterPolicy` - Core EKS cluster permissions
- `AmazonEKSVPCResourceController` - ENI management for pod networking

**Permissions Summary:**
- Create and manage Elastic Network Interfaces (ENIs)
- Describe EC2 resources (VPC, subnets, security groups)
- Create CloudWatch log groups for control plane logs
- Tag resources managed by EKS

**Trust Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

**Usage:** Automatically used by EKS cluster during creation

---

### 2. EKS Node Group Role

**Role Name:** `cloudmart-dev-eks-node-role`

**Purpose:** IAM role for EC2 worker nodes in EKS cluster

**Assumed By:** `ec2.amazonaws.com` service

**Attached AWS Managed Policies:**
- `AmazonEKSWorkerNodePolicy` - Core worker node permissions
- `AmazonEKS_CNI_Policy` - VPC CNI plugin for pod networking
- `AmazonEC2ContainerRegistryReadOnly` - Pull images from ECR
- `AmazonSSMManagedInstanceCore` - SSM Session Manager access

**Attached Custom Policies:**
- `cloudmart-dev-cloudwatch-logs-policy` - CloudWatch Logs write access
- `cloudmart-dev-ecr-pull-policy` - Enhanced ECR access

**Permissions Summary:**
- Pull container images from ECR
- Write logs to CloudWatch Logs
- Register with EKS control plane
- Communicate with other nodes
- Access Systems Manager for remote management

**Security Notes:**
- ⚠️ Node roles should be minimized in favor of IRSA (pod-level roles)
- ✅ SSM access allows secure access without SSH
- ✅ Read-only ECR access prevents unauthorized image pushes

---

### 3. Frontend Service Account Role (IRSA)

**Role Name:** `cloudmart-dev-frontend-sa-role`

**Purpose:** IAM role for frontend pods (React/NGINX)

**Assumed By:** Kubernetes service account via OIDC

**Service Account:** `cloudmart-frontend-sa` in namespace `cloudmart-dev`

**Permissions:**
- **CloudWatch Logs:** Write application logs

**Trust Policy:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::ACCOUNT:oidc-provider/oidc.eks.REGION.amazonaws.com/id/CLUSTER_ID"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.REGION.amazonaws.com/id/CLUSTER_ID:sub": "system:serviceaccount:cloudmart-dev:cloudmart-frontend-sa",
          "oidc.eks.REGION.amazonaws.com/id/CLUSTER_ID:aud": "sts.amazonaws.com"
        }
      }
    }
  ]
}
```

**Rationale:** Frontend is stateless and only needs minimal logging capability

---

### 4. API Service Account Role (IRSA)

**Role Name:** `cloudmart-dev-api-sa-role`

**Purpose:** IAM role for API backend pods (Node.js/Python)

**Assumed By:** Kubernetes service account via OIDC

**Service Account:** `cloudmart-api-sa` in namespace `cloudmart-dev`

**Permissions:**
- **Parameter Store:** Read configuration from `/cloudmart/dev/*`
- **Secrets Manager:** Read secrets from `cloudmart/dev/*`
- **CloudWatch Logs:** Write application and audit logs

**Use Cases:**
- Retrieve database connection strings from Secrets Manager
- Load application configuration from Parameter Store
- Write structured logs for observability

**Security Notes:**
- ✅ Read-only access to secrets (cannot modify)
- ✅ Scoped to project/environment path
- ✅ No EC2 or infrastructure modification permissions

---

### 5. Worker Service Account Role (IRSA)

**Role Name:** `cloudmart-dev-worker-sa-role`

**Purpose:** IAM role for background worker pods

**Assumed By:** Kubernetes service account via OIDC

**Service Account:** `cloudmart-worker-sa` in namespace `cloudmart-dev`

**Permissions:**
- **Parameter Store:** Read configuration
- **Secrets Manager:** Read secrets
- **CloudWatch Logs:** Write logs
- **SES (Simple Email Service):** Send transactional emails
- **SQS (Optional):** Read/delete messages from job queues

**Use Cases:**
- Process order confirmations
- Send email notifications
- Handle background jobs from queue
- Generate reports

**SES Policy Details:**
```json
{
  "Effect": "Allow",
  "Action": ["ses:SendEmail", "ses:SendRawEmail"],
  "Resource": "*",
  "Condition": {
    "StringLike": {
      "ses:FromAddress": "noreply@cloudmart.example.com"
    }
  }
}
```

**Security Notes:**
- ✅ SES sending restricted to specific sender address
- ✅ SQS access scoped to project queues
- ⚠️ Worker has more permissions than API (principle of least privilege by service)

---

### 6. AWS Load Balancer Controller Role (IRSA)

**Role Name:** `cloudmart-dev-aws-lb-controller-role`

**Purpose:** IAM role for AWS Load Balancer Controller add-on

**Assumed By:** Kubernetes service account `aws-load-balancer-controller` in `kube-system`

**Permissions:**
- Create/modify/delete Application Load Balancers (ALBs)
- Create/modify/delete Network Load Balancers (NLBs)
- Create/modify security groups for load balancers
- Manage target groups and register targets
- Associate WAF web ACLs with load balancers
- Create service-linked roles for ELB

**Use Cases:**
- Automatically provision ALB when Ingress resources created
- Manage target group registration for pods
- Configure listener rules based on Ingress annotations

**Security Notes:**
- ✅ Comprehensive but necessary permissions for ALB/NLB management
- ✅ Condition keys restrict actions to EKS-managed resources
- ✅ Required for Kubernetes Ingress to work with AWS ALB

---

## Custom IAM Policies

### CloudWatch Logs Policy

**Policy Name:** `cloudmart-dev-cloudwatch-logs-policy`

**Purpose:** Allow writing application logs to CloudWatch Logs

**Permissions:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogStreams"
      ],
      "Resource": "arn:aws:logs:REGION:ACCOUNT:log-group:/aws/eks/cloudmart-dev*:*"
    }
  ]
}
```

**Resource Scoping:** Limited to `/aws/eks/cloudmart-dev*` log groups

---

### ECR Pull Policy

**Policy Name:** `cloudmart-dev-ecr-pull-policy`

**Purpose:** Allow pulling container images from ECR

**Permissions:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage"
      ],
      "Resource": "*"
    }
  ]
}
```

**Note:** `GetAuthorizationToken` requires wildcard resource (`*`)

---

### Parameter Store Policy

**Policy Name:** `cloudmart-dev-parameter-store-policy`

**Purpose:** Allow reading application configuration from Systems Manager Parameter Store

**Permissions:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ssm:GetParameter",
        "ssm:GetParameters",
        "ssm:GetParametersByPath"
      ],
      "Resource": "arn:aws:ssm:REGION:ACCOUNT:parameter/cloudmart/dev/*"
    },
    {
      "Effect": "Allow",
      "Action": ["ssm:DescribeParameters"],
      "Resource": "*"
    }
  ]
}
```

**Resource Scoping:** Limited to `/cloudmart/dev/*` parameter path

**Parameter Store Hierarchy:**
```
/cloudmart/dev/
├── api/
│   ├── log-level
│   ├── cache-ttl
│   └── feature-flags
├── worker/
│   ├── queue-name
│   └── batch-size
└── common/
    ├── region
    └── environment
```

---

### Secrets Manager Policy

**Policy Name:** `cloudmart-dev-secrets-manager-policy`

**Purpose:** Allow reading sensitive data from AWS Secrets Manager

**Permissions:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:REGION:ACCOUNT:secret:cloudmart/dev/*"
    },
    {
      "Effect": "Allow",
      "Action": ["secretsmanager:ListSecrets"],
      "Resource": "*"
    }
  ]
}
```

**Resource Scoping:** Limited to `cloudmart/dev/*` secret path

**Secrets Hierarchy:**
```
cloudmart/dev/
├── database/
│   ├── master-password
│   ├── app-username
│   └── app-password
├── redis/
│   └── auth-token
├── jwt/
│   ├── signing-key
│   └── refresh-key
└── api-keys/
    ├── stripe-key
    └── sendgrid-key
```

---

## IRSA (IAM Roles for Service Accounts) Implementation

### What is IRSA?

IRSA allows Kubernetes pods to assume IAM roles using the EKS OIDC provider, providing:

1. **Fine-grained permissions:** Each pod can have its own IAM role
2. **No shared credentials:** No access keys stored in pods
3. **Automatic credential rotation:** Temporary credentials refresh automatically
4. **CloudTrail audit:** Track which pod made which AWS API call

### How IRSA Works

1. EKS cluster exposes an OIDC endpoint
2. Pod's service account has annotation with IAM role ARN
3. AWS SDK in pod requests credentials from OIDC endpoint
4. OIDC endpoint returns signed JWT token
5. Pod exchanges JWT for AWS temporary credentials via STS
6. Pod uses temporary credentials to access AWS services

### Enabling IRSA

IRSA is enabled in two phases:

**Phase 1 (Current - Step 1.4):** Create IAM roles with placeholder trust policies

**Phase 2 (After EKS Creation - Step 2.1):** Update trust policies with actual OIDC provider ARN

### Kubernetes Service Account Example
```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cloudmart-api-sa
  namespace: cloudmart-dev
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/cloudmart-dev-api-sa-role
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cloudmart-api
spec:
  template:
    spec:
      serviceAccountName: cloudmart-api-sa  # Use the service account
      containers:
      - name: api
        image: 123456789012.dkr.ecr.eu-central-1.amazonaws.com/cloudmart/api:latest
        # AWS SDK will automatically use IRSA credentials
```

---

## Security Best Practices

### Implemented

- ✅ **Least Privilege:** Each role has minimum required permissions
- ✅ **Resource Scoping:** Policies limited to specific ARN patterns
- ✅ **Condition Keys:** Trust policies include strict conditions
- ✅ **No Hardcoded Credentials:** All credentials via IRSA or instance profiles
- ✅ **Separate Roles:** Different roles for different services
- ✅ **Read-Only Where Possible:** Secrets/Parameter Store access is read-only
- ✅ **CloudTrail Logging:** All role assumptions logged

### Recommendations

- 🔄 **Regular Audits:** Monthly review of IAM Access Analyzer findings
- 🔄 **Permission Boundaries:** Consider adding permission boundaries for developer roles
- 🔄 **Session Duration:** Reduce session duration for sensitive roles
- 🔄 **MFA:** Require MFA for roles with write permissions (future enhancement)
- 🔄 **Tag-Based Access:** Implement tag-based ABAC (Attribute-Based Access Control)

---

## Monitoring and Auditing

### CloudTrail Events to Monitor

- `AssumeRole` - Track which services/pods assume roles
- `AssumeRoleWithWebIdentity` - Track IRSA credential requests
- Denied API calls - Identify missing permissions
- `GetSecretValue` - Audit secret access
- `GetParameter` - Audit configuration access

### IAM Access Analyzer

Enable IAM Access Analyzer to identify:
- Overly permissive policies
- External access to resources
- Unused roles and policies
- Public access grants

### Alerts to Configure

1. **Failed AssumeRole attempts:** Possible misconfiguration or attack
2. **Secrets access from unexpected IPs:** Potential credential theft
3. **Policy changes:** Track modifications to IAM policies
4. **New role creation:** Alert on unauthorized role creation

---

## Troubleshooting

### Common Issues

**Problem:** Pod cannot assume IAM role
**Solution:**
1. Check service account annotation has correct role ARN
2. Verify OIDC provider is configured in IAM trust policy
3. Confirm pod is using correct service account
4. Check CloudTrail for AssumeRoleWithWebIdentity errors

**Problem:** Access denied when accessing Secrets Manager
**Solution:**
1. Verify secret path matches policy resource ARN pattern
2. Check secret exists in correct region
3. Confirm role has `secretsmanager:GetSecretValue` permission
4. Verify KMS key policy allows decrypt (if using custom KMS key)

**Problem:** EKS node group role not working
**Solution:**
1. Ensure role has trust policy for `ec2.amazonaws.com`
2. Verify node group is using the correct instance profile
3. Check required managed policies are attached
4. Confirm VPC/subnet allow EC2 instances to reach AWS APIs

---

## Cost Impact

IAM roles and policies themselves are **free** - no charges from AWS.

Indirect costs:
- CloudTrail logging: ~$2/100k events
- IAM Access Analyzer: $0.20/analyzer/month

---

## References

- [EKS IAM Roles Documentation](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [AWS Load Balancer Controller IAM Policy](https://kubernetes-sigs.github.io/aws-load-balancer-controller/latest/deploy/installation/)
- CloudMart Terraform Module: `terraform/modules/iam/`

---

**Document Owner:** CloudMart DevOps Team  
**Review Schedule:** Quarterly  
**Next Review:** $(date -d '+3 months' +"%Y-%m-%d" 2>/dev/null || date -v +3m +"%Y-%m-%d")
# AWS Account Information

## Account Details

**Document created:** $(date +%Y-%m-%d)

### Primary Information
```bash
# Get Account ID
aws sts get-caller-identity --query Account --output text

# Get Account Alias (if set)
aws iam list-account-aliases --query 'AccountAliases[0]' --output text

# Get IAM User ARN
aws sts get-caller-identity --query Arn --output text
```

**Account ID:** `197423061144`  
**Primary Region:** `eu-central-1` (Frankfurt)  
**IAM User:** `cloudmart_user`  
**Billing Email:** `REPLACE_WITH_YOUR_EMAIL`

### Service Quotas (as of setup date)

| Service | Quota | Current Usage |
|---------|-------|---------------|
| EC2 On-Demand Instances | 20+ | 0 |
| VPCs per Region | 5+ | 0 |
| EKS Clusters | 100 | 0 |
| RDS DB Instances | 40 | 0 |
| ElastiCache Nodes | 90 | 0 |

### Budget Configuration

- **Monthly Budget:** $50 USD
- **Alerts at:** 80%, 100% (actual), 100% (forecasted)
- **Alert Email:** `REPLACE_WITH_YOUR_EMAIL`
- **Cost Allocation Tag:** `Project=CloudMart`

### Enabled Services

- ✅ Amazon EKS (Elastic Kubernetes Service)
- ✅ Amazon EC2 (Elastic Compute Cloud)
- ✅ Amazon VPC (Virtual Private Cloud)
- ✅ Amazon S3 (Simple Storage Service)
- ✅ Amazon RDS (Relational Database Service)
- ✅ Amazon ElastiCache (Redis)
- ✅ Amazon DynamoDB
- ✅ Amazon ECR (Elastic Container Registry)
- ✅ Amazon CloudWatch
- ✅ Amazon Cognito
- ✅ AWS WAF (Web Application Firewall)
- ✅ AWS Lambda
- ✅ Amazon API Gateway
- ✅ AWS CloudFront
- ✅ AWS Route53
- ✅ AWS Secrets Manager
- ✅ AWS Systems Manager (Parameter Store)
- ✅ AWS KMS (Key Management Service)
- ✅ AWS GuardDuty
- ✅ AWS CloudTrail
- ✅ AWS Backup

### Cost Monitoring

Monitor costs at:
- AWS Cost Explorer: https://console.aws.amazon.com/cost-management/home
- AWS Budgets: https://console.aws.amazon.com/billing/home\#/budgets

### Notes

- All resources will be tagged with `Project=CloudMart` for cost tracking
- Primary region: eu-central-1 (lower latency for European users)
- Session tokens expire every 12 hours - use `refresh_aws_session` to renew

## IAM Policy Configuration (Updated)

### Issue Resolved
Hit AWS limit of 10 managed policies per group. Switched to inline policy approach.

### Current Configuration
- **Inline Policy Name:** `CloudMartComprehensiveAccess`
- **Attached to:** `cloudmart_user_group`
- **Scope:** Full access to all CloudMart required services

### Included Permissions
- S3, DynamoDB, EC2, EKS, RDS, ElastiCache
- ECR, CloudWatch, Cognito, Lambda, API Gateway
- IAM (read + PassRole), Secrets Manager, Systems Manager
- KMS, ELB, Auto Scaling, CloudFormation
- WAF, GuardDuty, CloudFront, Route53, ACM
- CloudTrail (read-only), Backup, SNS, SQS
- Service Quotas (read), STS

### Security Note
These are broad permissions suitable for development and demonstration. 
Before any production use, implement least-privilege policies with specific resource ARNs.

### Policy Location
Full policy definition: `docs/iam-inline-policy-cloudmart.json`

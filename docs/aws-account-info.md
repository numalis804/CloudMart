# AWS Account Information - CloudMart Project

## Account Details

**Account ID:** 197423061144
**Primary Region:** eu-central-1
**AWS CLI Profile:** cloudmart_user
**IAM User ARN:** arn:aws:iam::197423061144:user/cloudmart_user

## Billing Information

**Billing Email:** [Update manually after checking AWS Console]
**Budget Alert:** CloudMart-Monthly-Budget ($100/month with 50%, 80%, 100% alerts)
**Cost Allocation Tags:**
- Project: CloudMart
- ManagedBy: Terraform
- Environment: dev/staging/prod

## Service Quotas (Verified: 2025-10-17)

| Service | Resource | Current Quota | Required |
|---------|----------|---------------|----------|
| EKS | Clusters per region | 100 | 3 |
| VPC | VPCs per region | 5 | 3 |
| EC2 | On-Demand instances | Check console | 10-15 |
| VPC | NAT Gateways per AZ | 5 | 3 |
| EC2 | Elastic IPs | 5 | 3-5 |
| RDS | DB Instances | 40 | 2-3 |
| ElastiCache | Nodes per region | 300 | 4-6 |

## Enabled Services

- ✓ Amazon EKS (Elastic Kubernetes Service)
- ✓ Amazon S3 (Simple Storage Service)
- ✓ Amazon DynamoDB
- ✓ Amazon ECR (Elastic Container Registry)
- ✓ Amazon RDS (Relational Database Service)
- ✓ Amazon ElastiCache (Redis)
- ✓ AWS Lambda
- ✓ Amazon API Gateway
- ✓ Amazon CloudWatch
- ✓ AWS Secrets Manager
- ✓ AWS Systems Manager (Parameter Store)
- ✓ Amazon Cognito
- ✓ AWS WAF (Web Application Firewall)
- ✓ Amazon CloudFront
- ✓ Amazon Route 53

## Cost Control Measures

1. Budget alerts configured at 50%, 80%, 100% thresholds
2. Resource tagging strategy for cost allocation
3. Regular cost review scheduled (weekly during development)
4. Scheduled shutdown of dev/staging environments outside working hours (future)
5. Use of spot instances where appropriate

## Security Contacts

**Primary Contact:** [Your Name]
**Email:** [Your Email]
**GitHub:** numalis804

## Notes

- This is a demonstration/portfolio project
- All resources will be tagged with Project=CloudMart
- Resources should be destroyed when not actively developing
- Final teardown checklist available in Phase 16 of project guide

---
*Last Updated: Fri Oct 17 12:17:26 CEST 2025*

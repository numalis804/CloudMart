# IAM Configuration - Clean State

## Overview
Single comprehensive inline policy attached to group. User inherits all permissions through group membership.

## Configuration

### IAM Group: cloudmart_user_group
- **Inline Policy:** CloudMartComprehensiveAccess
- **Members:** cloudmart_user

### IAM User: cloudmart_user
- **Direct Policies:** None (inherits from group)
- **Group Membership:** cloudmart_user_group

## Permissions Summary

The `CloudMartComprehensiveAccess` inline policy provides full access to:
- Compute: EC2, EKS, Lambda
- Storage: S3, EBS
- Database: RDS, DynamoDB, ElastiCache
- Networking: VPC, ELB, CloudFront, Route53
- Container: ECR
- Security: IAM, KMS, Secrets Manager, WAF, GuardDuty
- Monitoring: CloudWatch, CloudTrail
- CI/CD: CodeBuild, CodeDeploy, CodePipeline
- Messaging: SNS, SQS
- API: API Gateway
- Cost: Cost Explorer, Budgets

## Cleanup History
- Removed 10 duplicate/redundant policies from group
- Removed 10 policies from user (now inherits from group)
- Deleted 4 orphaned custom managed policies
- Consolidated to single comprehensive inline policy

## Maintenance
- Policy location: IAM Console → Groups → cloudmart_user_group → Permissions
- To modify: Edit the CloudMartComprehensiveAccess inline policy
- No individual user policies needed

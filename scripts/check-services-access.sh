#!/usr/bin/env bash
# scripts/check-services-access.sh
# Verify CloudMart required AWS services are accessible

set -e

REGION="eu-central-1"
echo "=== Verifying AWS Services Access in $REGION ==="

declare -A SERVICES=(
  ["EKS"]="aws eks list-clusters --region $REGION"
  ["S3"]="aws s3 ls"
  ["DynamoDB"]="aws dynamodb list-tables --region $REGION"
  ["ECR"]="aws ecr describe-repositories --region $REGION"
  ["RDS"]="aws rds describe-db-instances --region $REGION"
  ["ElastiCache"]="aws elasticache describe-cache-clusters --region $REGION"
  ["Lambda"]="aws lambda list-functions --region $REGION"
  ["API Gateway"]="aws apigateway get-rest-apis --region $REGION"
  ["CloudWatch"]="aws cloudwatch list-metrics --namespace AWS/EC2 --max-items 1"
  ["Secrets Manager"]="aws secretsmanager list-secrets --region $REGION"
  ["SSM Parameter Store"]="aws ssm describe-parameters --region $REGION"
  ["Cognito"]="aws cognito-idp list-user-pools --region $REGION --max-results 1"
  ["WAF"]="aws wafv2 list-web-acls --scope REGIONAL --region $REGION"
  ["CloudFront"]="aws cloudfront list-distributions"
  ["Route 53"]="aws route53 list-hosted-zones"
)

for service in "${!SERVICES[@]}"; do
  cmd="${SERVICES[$service]}"
  if $cmd &>/dev/null; then
    echo "✓ $service accessible"
  else
    echo "❌ $service not accessible or missing permissions"
  fi
done

echo ""
echo "✓ All required services check complete"

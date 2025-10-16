#!/usr/bin/env bash
# scripts/check-availability.sh
# Check if services are available in eu-central-1

echo "🔍 Verifying AWS services availability in eu-central-1..."

# EKS
aws eks list-clusters --region eu-central-1 &>/dev/null && echo "✅ EKS available" || echo "❌ EKS not available"

# EC2
aws ec2 describe-instances --region eu-central-1 --max-results 1 &>/dev/null && echo "✅ EC2 available" || echo "❌ EC2 not available"

# S3 (global service)
aws s3 ls &>/dev/null && echo "✅ S3 available" || echo "❌ S3 not available"

# DynamoDB
aws dynamodb list-tables --region eu-central-1 &>/dev/null && echo "✅ DynamoDB available" || echo "❌ DynamoDB not available"

# RDS
aws rds describe-db-instances --region eu-central-1 --max-records 1 &>/dev/null && echo "✅ RDS available" || echo "❌ RDS not available"

# ElastiCache
aws elasticache describe-cache-clusters --region eu-central-1 --max-records 1 &>/dev/null && echo "✅ ElastiCache available" || echo "❌ ElastiCache not available"

# ECR
aws ecr describe-repositories --region eu-central-1 --max-results 1 &>/dev/null && echo "✅ ECR available" || echo "❌ ECR not available"

# CloudWatch
aws cloudwatch list-metrics --region eu-central-1 --max-records 1 &>/dev/null && echo "✅ CloudWatch available" || echo "❌ CloudWatch not available"

# Cognito
aws cognito-idp list-user-pools --region eu-central-1 --max-results 1 &>/dev/null && echo "✅ Cognito available" || echo "❌ Cognito not available"

# Lambda
aws lambda list-functions --region eu-central-1 --max-items 1 &>/dev/null && echo "✅ Lambda available" || echo "❌ Lambda not available"

# API Gateway
aws apigateway get-rest-apis --region eu-central-1 --limit 1 &>/dev/null && echo "✅ API Gateway available" || echo "❌ API Gateway not available"
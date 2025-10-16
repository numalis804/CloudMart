#!/usr/bin/env bash
# scripts/check-quotas.sh
# Check AWS Service Quotas for CloudMart requirements

set -euo pipefail

REGION=${1:-eu-central-1}

echo "🔍 Checking AWS Service Quotas for region: ${REGION}"
echo "================================================"

# EC2 Quotas
echo -e "\n📦 EC2 Quotas:"
aws service-quotas get-service-quota \
  --service-code ec2 \
  --quota-code L-1216C47A \
  --region ${REGION} \
  --query 'Quota.[QuotaName,Value]' \
  --output text 2>/dev/null || echo "Running On-Demand Standard instances: (check manually)"

# VPC Quotas
echo -e "\n🌐 VPC Quotas:"
aws service-quotas get-service-quota \
  --service-code vpc \
  --quota-code L-F678F1CE \
  --region ${REGION} \
  --query 'Quota.[QuotaName,Value]' \
  --output text 2>/dev/null || echo "VPCs per region: 5 (default)"

aws service-quotas get-service-quota \
  --service-code vpc \
  --quota-code L-A4707A72 \
  --region ${REGION} \
  --query 'Quota.[QuotaName,Value]' \
  --output text 2>/dev/null || echo "Internet gateways per region: 5 (default)"

# EKS Quotas
echo -e "\n☸️  EKS Quotas:"
aws service-quotas get-service-quota \
  --service-code eks \
  --quota-code L-1194D53C \
  --region ${REGION} \
  --query 'Quota.[QuotaName,Value]' \
  --output text 2>/dev/null || echo "Clusters: 100 (default)"

aws service-quotas get-service-quota \
  --service-code eks \
  --quota-code L-F2A6C128 \
  --region ${REGION} \
  --query 'Quota.[QuotaName,Value]' \
  --output text 2>/dev/null || echo "Managed node groups per cluster: 30 (default)"

# RDS Quotas
echo -e "\n💾 RDS Quotas:"
aws service-quotas get-service-quota \
  --service-code rds \
  --quota-code L-7B6409FD \
  --region ${REGION} \
  --query 'Quota.[QuotaName,Value]' \
  --output text 2>/dev/null || echo "DB instances: 40 (default)"

# ElastiCache Quotas
echo -e "\n🔴 ElastiCache Quotas:"
aws service-quotas get-service-quota \
  --service-code elasticache \
  --quota-code L-14EC45A7 \
  --region ${REGION} \
  --query 'Quota.[QuotaName,Value]' \
  --output text 2>/dev/null || echo "Nodes per cluster: 90 (default)"

echo -e "\n✅ Quota check complete"
echo "💡 If any quotas are too low, request increase via AWS Console:"
echo "   https://console.aws.amazon.com/servicequotas/"
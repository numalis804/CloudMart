#!/usr/bin/env bash
# scripts/check-service-quotas.sh
# Verify AWS quotas for CloudMart environments

set -e

echo "=== Checking Service Quotas ==="

declare -A QUOTAS=(
  ["EKS Clusters"]="eks:L-1194D53C:100"
  ["VPCs"]="vpc:L-F678F1CE:5"
  ["EC2 On-Demand"]="ec2:L-1216C47A:Check console for current limit"
  ["NAT Gateways"]="vpc:L-FE5A380F:5"
  ["Elastic IPs"]="ec2:L-0263D0A3:5"
  ["RDS DB Instances"]="rds:L-7B6409FD:40"
  ["ElastiCache Nodes"]="elasticache:L-C350B5F9:300"
)

REGION="eu-central-1"

for service in "${!QUOTAS[@]}"; do
  IFS=':' read -r service_code quota_code default <<< "${QUOTAS[$service]}"
  value=$(aws service-quotas get-service-quota \
    --service-code "$service_code" \
    --quota-code "$quota_code" \
    --region "$REGION" \
    --query 'Quota.Value' \
    --output text 2>/dev/null || echo "$default")
  echo "$service: $value"
done

echo "✓ Service Quotas check complete"

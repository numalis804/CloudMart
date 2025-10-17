#!/bin/bash
# Create comprehensive security verification script

set -e

echo "=== CloudMart Security Groups Verification ==="
echo ""

# Change to terraform directory
cd ~/GitHub/CloudMart/terraform/environments/dev

# Get VPC and Security Group IDs
VPC_ID=$(terraform output -raw vpc_id)
ALB_SG_ID=$(terraform output -raw alb_security_group_id)
EKS_SG_ID=$(terraform output -raw eks_nodes_security_group_id)
RDS_SG_ID=$(terraform output -raw rds_security_group_id)
CACHE_SG_ID=$(terraform output -raw elasticache_security_group_id)

echo "VPC ID: $VPC_ID"
echo ""

# Function to check if security group has rules exposed to internet
check_internet_exposure() {
  local sg_id=$1
  local sg_name=$2
  local allowed_ports=$3
  
  local exposed_rules=$(aws ec2 describe-security-group-rules \
    --filters "Name=group-id,Values=$sg_id" \
    --query 'SecurityGroupRules[?IsEgress==`false` && CidrIpv4==`0.0.0.0/0`]' \
    --output json 2>/dev/null)
  
  if [ "$exposed_rules" == "[]" ] || [ -z "$exposed_rules" ]; then
    echo "✓ $sg_name: No internet exposure"
    return 0
  else
    local exposed_ports=$(echo "$exposed_rules" | jq -r '.[].FromPort' 2>/dev/null | sort -u)
    if [ -z "$allowed_ports" ]; then
      echo "⚠️ $sg_name: UNEXPECTED internet exposure on ports: $exposed_ports"
      return 1
    else
      echo "✓ $sg_name: Internet exposure on expected ports: $exposed_ports"
      return 0
    fi
  fi
}

# Function to verify security group reference
check_sg_reference() {
  local sg_id=$1
  local sg_name=$2
  local expected_source=$3
  local port=$4
  
  local rules=$(aws ec2 describe-security-group-rules \
    --filters "Name=group-id,Values=$sg_id" \
    --query "SecurityGroupRules[?IsEgress==\`false\` && ReferencedGroupInfo.GroupId==\`$expected_source\` && FromPort==\`$port\`]" \
    --output json 2>/dev/null)
  
  if [ "$rules" != "[]" ] && [ -n "$rules" ]; then
    echo "✓ $sg_name: Has ingress from expected source on port $port"
    return 0
  else
    echo "⚠️ $sg_name: Missing expected ingress from source on port $port"
    return 1
  fi
}

echo "=== Internet Exposure Check ==="
check_internet_exposure "$ALB_SG_ID" "ALB" "80,443"
check_internet_exposure "$EKS_SG_ID" "EKS Nodes" ""
check_internet_exposure "$RDS_SG_ID" "RDS" ""
check_internet_exposure "$CACHE_SG_ID" "ElastiCache" ""

echo ""
echo "=== Data Tier Access Control Check ==="
check_sg_reference "$RDS_SG_ID" "RDS" "$EKS_SG_ID" "5432"
check_sg_reference "$CACHE_SG_ID" "ElastiCache" "$EKS_SG_ID" "6379"

echo ""
echo "=== EKS Nodes Access Control Check ==="
# Check EKS can receive from ALB
EKS_FROM_ALB=$(aws ec2 describe-security-group-rules \
  --filters "Name=group-id,Values=$EKS_SG_ID" \
  --query "SecurityGroupRules[?IsEgress==\`false\` && ReferencedGroupInfo.GroupId==\`$ALB_SG_ID\`]" \
  --output json 2>/dev/null)

if [ "$EKS_FROM_ALB" != "[]" ] && [ -n "$EKS_FROM_ALB" ]; then
  echo "✓ EKS Nodes: Can receive traffic from ALB"
else
  echo "⚠️ EKS Nodes: Cannot receive traffic from ALB"
fi

# Check EKS inter-node communication
EKS_INTER_NODE=$(aws ec2 describe-security-group-rules \
  --filters "Name=group-id,Values=$EKS_SG_ID" \
  --query "SecurityGroupRules[?IsEgress==\`false\` && ReferencedGroupInfo.GroupId==\`$EKS_SG_ID\`]" \
  --output json 2>/dev/null)

if [ "$EKS_INTER_NODE" != "[]" ] && [ -n "$EKS_INTER_NODE" ]; then
  echo "✓ EKS Nodes: Inter-node communication enabled"
else
  echo "⚠️ EKS Nodes: Inter-node communication not configured"
fi

echo ""
echo "=== Sensitive Ports Check ==="
# Check for common sensitive ports exposed to internet
SENSITIVE_PORTS="22 3389 5432 6379 3306 1433 27017"
ISSUES_FOUND=0

for sg_id in $ALB_SG_ID $EKS_SG_ID $RDS_SG_ID $CACHE_SG_ID; do
  SG_NAME=$(aws ec2 describe-security-groups \
    --group-ids $sg_id \
    --query 'SecurityGroups[0].GroupName' \
    --output text 2>/dev/null)
  
  for port in $SENSITIVE_PORTS; do
    EXPOSED=$(aws ec2 describe-security-group-rules \
      --filters "Name=group-id,Values=$sg_id" \
      --query "SecurityGroupRules[?IsEgress==\`false\` && CidrIpv4==\`0.0.0.0/0\` && FromPort==\`$port\`]" \
      --output json 2>/dev/null)
    
    if [ "$EXPOSED" != "[]" ] && [ -n "$EXPOSED" ]; then
      echo "⚠️ WARNING: $SG_NAME exposes sensitive port $port to internet"
      ISSUES_FOUND=1
    fi
  done
done

if [ $ISSUES_FOUND -eq 0 ]; then
  echo "✓ No sensitive ports exposed to internet"
fi

echo ""
echo "=== Security Group Rules Summary ==="
aws ec2 describe-security-groups \
  --group-ids $ALB_SG_ID $EKS_SG_ID $RDS_SG_ID $CACHE_SG_ID \
  --query 'SecurityGroups[*].[GroupName,GroupId,IpPermissions[*].[FromPort,ToPort,IpRanges[0].CidrIp]]' \
  --output table

echo ""
echo "=== Verification Complete ==="

#!/bin/bash
set -e

echo "=== Configuring kubectl for CloudMart EKS Cluster ==="
echo ""

# Get cluster name from Terraform
cd ~/GitHub/CloudMart/terraform/environments/dev
CLUSTER_NAME=$(terraform output -raw eks_cluster_id 2>/dev/null)
REGION=$(terraform output -raw aws_region 2>/dev/null || echo "eu-central-1")

if [ -z "$CLUSTER_NAME" ]; then
  echo "❌ Error: Could not get cluster name from Terraform outputs"
  exit 1
fi

echo "Cluster: $CLUSTER_NAME"
echo "Region: $REGION"
echo ""

# Configure kubeconfig
aws eks update-kubeconfig \
  --name $CLUSTER_NAME \
  --region $REGION \
  --alias cloudmart-dev

echo ""
echo "✓ kubectl configured for context: cloudmart-dev"
echo ""

# Verify access
echo "=== Cluster Information ==="
kubectl cluster-info

echo ""
echo "=== Cluster Version ==="
kubectl version --short 2>/dev/null || kubectl version

echo ""
echo "=== Nodes (will be empty until node groups created) ==="
kubectl get nodes || echo "No nodes yet - will be created in Step 2.2"

echo ""
echo "=== System Pods ==="
kubectl get pods -n kube-system

echo ""
echo "=== Current Context ==="
kubectl config current-context

echo ""
echo "✓ kubectl configuration complete"
echo ""
echo "Next: Create EKS node groups (Step 2.2)"

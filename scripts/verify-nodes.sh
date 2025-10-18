#!/bin/bash
set -e

echo "=== EKS Node Groups Verification ==="
echo ""

# Get cluster info
cd ~/GitHub/CloudMart/terraform/environments/dev
CLUSTER_NAME=$(terraform output -raw eks_cluster_id)

echo "Cluster: $CLUSTER_NAME"
echo ""

# Check node groups in AWS
echo "=== AWS Node Groups ==="
aws eks list-nodegroups --cluster-name $CLUSTER_NAME --output table

echo ""
echo "=== On-Demand Node Group Details ==="
aws eks describe-nodegroup \
  --cluster-name $CLUSTER_NAME \
  --nodegroup-name cloudmart-dev-ondemand-v2 \
  --query '{
    NodeGroupName: nodegroup.nodegroupName,
    Status: nodegroup.status,
    DesiredSize: nodegroup.scalingConfig.desiredSize,
    InstanceTypes: nodegroup.instanceTypes
  }'\
  --output table

if aws eks describe-nodegroup --cluster-name $CLUSTER_NAME --nodegroup-name cloudmart-dev-spot-v2 2>/dev/null; then
  echo ""
  echo "=== Spot Node Group Details ==="
  aws eks describe-nodegroup \
    --cluster-name $CLUSTER_NAME \
    --nodegroup-name cloudmart-dev-spot-v2 \
    --query '{
    NodeGroupName: nodegroup.nodegroupName,
    Status: nodegroup.status,
    DesiredSize: nodegroup.scalingConfig,
    InstanceTypes: nodegroup.instanceTypes
  }'\
    --output table
fi

# Check nodes in Kubernetes
echo ""
echo "=== Kubernetes Nodes ==="
kubectl get nodes

echo ""
echo "=== Node Details ==="
kubectl get nodes -o wide

echo ""
echo "=== Node Capacities ==="
kubectl top nodes 2>/dev/null || echo "Metrics server not yet installed"

echo ""
echo "=== Node Labels ==="
kubectl get nodes --show-labels

echo ""
echo "=== System Pods ==="
kubectl get pods -n kube-system

echo ""
echo "=== Node Conditions ==="
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.conditions[?(@.type=="Ready")].status}{"\n"}{end}'

echo ""
echo "=== Resource Usage ==="
kubectl describe nodes | grep -A 5 "Allocated resources"

echo ""
echo "✓ Node verification complete"

#!/bin/bash
set -e

echo "=== EKS Add-ons Verification ==="
echo ""

cd ~/GitHub/CloudMart/terraform/environments/dev
CLUSTER_NAME=$(terraform output -raw eks_cluster_id)

# Check EKS add-ons
echo "1. EKS Managed Add-ons:"
aws eks list-addons --cluster-name $CLUSTER_NAME --output table

echo ""
echo "2. CoreDNS:"
kubectl get deployment coredns -n kube-system
kubectl get pods -n kube-system -l k8s-app=kube-dns

echo ""
echo "3. EBS CSI Driver:"
kubectl get deployment ebs-csi-controller -n kube-system
kubectl get daemonset ebs-csi-node -n kube-system

echo ""
echo "4. Metrics Server:"
kubectl get deployment metrics-server -n kube-system
kubectl top nodes

echo ""
echo "5. AWS Load Balancer Controller:"
kubectl get deployment aws-load-balancer-controller -n kube-system

echo ""
echo "6. Service Accounts with IRSA:"
kubectl get sa -n cloudmart-dev
kubectl describe sa cloudmart-api-sa -n cloudmart-dev | grep "eks.amazonaws.com/role-arn"

echo ""
echo "7. IRSA Roles in AWS:"
aws iam list-roles --query "Roles[?contains(RoleName, 'cloudmart-dev') && contains(RoleName, 'sa-role')].RoleName" --output table

echo ""
echo "✓ All add-ons verified"

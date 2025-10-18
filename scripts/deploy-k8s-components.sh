#!/bin/bash
set -e

echo "=== Deploying Kubernetes Components ==="
echo ""

# Get cluster info
cd ~/GitHub/CloudMart/terraform/environments/dev
CLUSTER_NAME=$(terraform output -raw eks_cluster_id)
AWS_REGION=$(terraform output -raw aws_region 2>/dev/null || echo "eu-central-1")
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
ALB_CONTROLLER_ROLE_ARN=$(terraform output -raw aws_load_balancer_controller_role_arn)

echo "Cluster: $CLUSTER_NAME"
echo "Region: $AWS_REGION"
echo "Account: $AWS_ACCOUNT_ID"
echo ""

# 1. Install Metrics Server
echo "=========================================="
echo "1. Installing Metrics Server"
echo "=========================================="
echo ""

kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

echo "Waiting for Metrics Server to be ready..."
kubectl wait --for=condition=available --timeout=300s deployment/metrics-server -n kube-system || true

echo ""
echo "✓ Metrics Server installed"
kubectl get deployment metrics-server -n kube-system

# 2. Add Helm repositories
echo ""
echo "=========================================="
echo "2. Adding Helm Repositories"
echo "=========================================="
echo ""

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

helm repo add eks https://aws.github.io/eks-charts
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm repo update

echo "✓ Helm repositories added"

# 3. Install AWS Load Balancer Controller
echo ""
echo "=========================================="
echo "3. Installing AWS Load Balancer Controller"
echo "=========================================="
echo ""

# Create namespace if it doesn't exist
kubectl create namespace cloudmart-dev --dry-run=client -o yaml | kubectl apply -f -

# Install AWS Load Balancer Controller
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$CLUSTER_NAME \
  --set serviceAccount.create=true \
  --set serviceAccount.name=aws-load-balancer-controller \
  --set serviceAccount.annotations."eks\.amazonaws\.com/role-arn"=$ALB_CONTROLLER_ROLE_ARN \
  --set region=$AWS_REGION \
  --set vpcId=$(cd ~/GitHub/CloudMart/terraform/environments/dev && terraform output -raw vpc_id) \
  --wait

echo ""
echo "✓ AWS Load Balancer Controller installed"
kubectl get deployment aws-load-balancer-controller -n kube-system

# 4. Create Kubernetes Service Accounts with IRSA
echo ""
echo "=========================================="
echo "4. Creating Kubernetes Service Accounts"
echo "=========================================="
echo ""

cd ~/GitHub/CloudMart/terraform/environments/dev
FRONTEND_ROLE_ARN=$(terraform output -raw frontend_sa_role_arn)
API_ROLE_ARN=$(terraform output -raw api_sa_role_arn)
WORKER_ROLE_ARN=$(terraform output -raw worker_sa_role_arn)

cat > /tmp/service-accounts.yaml << SAEOF
---
apiVersion: v1
kind: Namespace
metadata:
  name: cloudmart-dev
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cloudmart-frontend-sa
  namespace: cloudmart-dev
  annotations:
    eks.amazonaws.com/role-arn: ${FRONTEND_ROLE_ARN}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cloudmart-api-sa
  namespace: cloudmart-dev
  annotations:
    eks.amazonaws.com/role-arn: ${API_ROLE_ARN}
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: cloudmart-worker-sa
  namespace: cloudmart-dev
  annotations:
    eks.amazonaws.com/role-arn: ${WORKER_ROLE_ARN}
SAEOF

kubectl apply -f /tmp/service-accounts.yaml
rm /tmp/service-accounts.yaml

echo "✓ Service accounts created"
kubectl get sa -n cloudmart-dev

# 5. Test CoreDNS
echo ""
echo "=========================================="
echo "5. Testing CoreDNS"
echo "=========================================="
echo ""

kubectl run test-dns --image=busybox:1.36 --restart=Never --rm -it -- nslookup kubernetes.default || true

echo "✓ CoreDNS tested"

# 6. Test EBS CSI Driver (create a PVC)
echo ""
echo "=========================================="
echo "6. Testing EBS CSI Driver"
echo "=========================================="
echo ""

cat > /tmp/test-pvc.yaml << PVCEOF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ebs-test
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: gp3
  resources:
    requests:
      storage: 1Gi
PVCEOF

kubectl apply -f /tmp/test-pvc.yaml
sleep 10
kubectl get pvc ebs-test -n default
kubectl delete pvc ebs-test -n default --wait=false
rm /tmp/test-pvc.yaml

echo "✓ EBS CSI Driver tested"

# Final verification
echo ""
echo "=========================================="
echo "   Deployment Complete! ✅"
echo "=========================================="
echo ""
echo "Installed Components:"
echo "  ✅ CoreDNS add-on"
echo "  ✅ EBS CSI Driver add-on"
echo "  ✅ Metrics Server"
echo "  ✅ AWS Load Balancer Controller"
echo "  ✅ IRSA Service Accounts"
echo ""
echo "Verification:"
echo ""

echo "Add-ons:"
kubectl get pods -n kube-system | grep -E "coredns|ebs-csi|metrics-server|aws-load-balancer-controller"

echo ""
echo "Service Accounts:"
kubectl get sa -n cloudmart-dev

echo ""
echo "Metrics (may take a minute to populate):"
kubectl top nodes || echo "  ⏳ Metrics not ready yet (normal, wait 1-2 minutes)"

echo ""
echo "=========================================="
echo "Ready for application deployments!"
echo "=========================================="

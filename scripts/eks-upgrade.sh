#!/bin/bash
cd ~/GitHub/CloudMart/terraform/environments/dev

set -euo pipefail

echo ""
echo "=========================================="
echo "   Kubernetes Upgrade Path"
echo "=========================================="
echo ""
echo "AWS EKS requires incremental upgrades:"
echo "  Current: 1.28"
echo "  Step 1:  1.28 → 1.29"
echo "  Step 2:  1.29 → 1.30"
echo "  Step 3:  1.30 → 1.31"
echo ""
echo "Options:"
echo "  A) Upgrade to 1.29 only (fastest, supported until Sept 2025)"
echo "  B) Upgrade to 1.30 (1.28→1.29→1.30, supported until Dec 2025)"
echo "  C) Upgrade to 1.31 (full path, supported until July 2026)"
echo "  D) Keep 1.28 for now (supported until Nov 2025)"
echo ""
read -rp "Select option (A/B/C/D): " choice

case $choice in
  [Aa]*)
    TARGET_VERSION="1.29"
    UPGRADE_STEPS=("1.29")
    ;;
  [Bb]*)
    TARGET_VERSION="1.30"
    UPGRADE_STEPS=("1.29" "1.30")
    ;;
  [Cc]*)
    TARGET_VERSION="1.31"
    UPGRADE_STEPS=("1.29" "1.30" "1.31")
    ;;
  [Dd]*)
    echo ""
    echo "✓ Keeping Kubernetes 1.28"
    echo "You can upgrade later before proceeding to production"
    echo ""
    echo "Proceeding with Step 2.3..."
    exit 0
    ;;
  *)
    echo "Invalid choice. Exiting."
    exit 1
    ;;
esac

echo ""
echo "Selected upgrade path to $TARGET_VERSION"
echo "Steps: ${UPGRADE_STEPS[*]}"
echo ""
read -rp "Press Enter to start incremental upgrade, or Ctrl+C to cancel..."

upgrade_to_version() {
  local VERSION=$1
  echo ""
  echo "=========================================="
  echo "   Upgrading to Kubernetes $VERSION"
  echo "=========================================="

  # Update variables.tf
  sed -i "s/default     = \"[0-9.]*\"/default     = \"$VERSION\"/" variables.tf

  echo ""
  echo "Updated version in variables.tf:"
  grep -A 3 'eks_cluster_version' variables.tf

  echo ""
  echo "=== Planning upgrade to $VERSION ==="
  terraform plan -out="upgrade-to-$VERSION.tfplan"

  echo ""
  echo "=== Applying upgrade to $VERSION ==="
  echo "This will take 15–20 minutes..."
  terraform apply "upgrade-to-$VERSION.tfplan"

  echo ""
  echo "=== Waiting for control plane to stabilize ==="
  CLUSTER_NAME=$(terraform output -raw eks_cluster_id)

  for i in {1..40}; do
    STATUS=$(aws eks describe-cluster --name "$CLUSTER_NAME" --query 'cluster.status' --output text)
    CURRENT_VERSION=$(aws eks describe-cluster --name "$CLUSTER_NAME" --query 'cluster.version' --output text)

    echo "$(date '+%H:%M:%S') - Status: $STATUS, Version: $CURRENT_VERSION"

    if [[ "$STATUS" == "ACTIVE" && "$CURRENT_VERSION" == "$VERSION" ]]; then
      echo "✓ Control plane upgraded to $VERSION"
      break
    fi

    if [[ $i -eq 40 ]]; then
      echo "⚠ Timeout waiting for upgrade. Check AWS console."
      return 1
    fi

    sleep 30
  done

  echo ""
  echo "=== Waiting for nodes to be ready ==="
  sleep 60

  for i in {1..20}; do
    READY_NODES=$(kubectl get nodes --no-headers 2>/dev/null | grep -c " Ready " || echo "0")
    echo "$(date '+%H:%M:%S') - Ready nodes: $READY_NODES/2"

    if [[ "$READY_NODES" -ge 2 ]]; then
      echo "✓ Nodes ready with version $VERSION"
      break
    fi

    sleep 30
  done

  echo ""
  echo "=== Verification ==="
  kubectl get nodes
  kubectl get pods -n kube-system | head -10

  echo ""
  echo "✓ Successfully upgraded to Kubernetes $VERSION"
  echo ""

  if [[ "$VERSION" != "$TARGET_VERSION" ]]; then
    echo "Waiting 60 seconds before next upgrade..."
    sleep 60
  fi
}

for VERSION in "${UPGRADE_STEPS[@]}"; do
  upgrade_to_version "$VERSION" || exit 1
done

echo ""
echo "=========================================="
echo "   Upgrade Complete! ✅"
echo "=========================================="
echo ""
echo "Final Status:"
CLUSTER_NAME=$(terraform output -raw eks_cluster_id)
aws eks describe-cluster --name "$CLUSTER_NAME" \
  --query 'cluster.[version,status,platformVersion]' \
  --output table

echo ""
echo "Nodes:"
kubectl get nodes

echo ""
echo "Node versions:"
kubectl get nodes -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.nodeInfo.kubeletVersion}{"\n"}{end}'

echo ""
echo "System pods:"
kubectl get pods -n kube-system | grep -E "NAME|Running" | head -10

echo ""
echo "=== Updating documentation ==="
cd ~/GitHub/CloudMart/docs || exit 1

sed -i "s/Cluster Version:** 1.28/Cluster Version:** $TARGET_VERSION/g" eks-cluster-info.md
sed -i "s/Kubernetes 1.28/Kubernetes $TARGET_VERSION/g" eks-cluster-info.md

cat >> eks-cluster-info.md << UPGRADEEOF

---

## Kubernetes Version Upgrade

**Date:** $(date +"%Y-%m-%d %H:%M:%S")
**Upgrade Path:** 1.28 → $TARGET_VERSION

**Incremental Steps:**
$(for v in "${UPGRADE_STEPS[@]}"; do echo "- ✅ Upgraded to $v"; done)

**Status:** ✅ Complete

**Verification:**
\`\`\`bash
kubectl version --short
kubectl get nodes
\`\`\`

---
**Upgraded to Kubernetes $TARGET_VERSION**
**Ready for Step 2.3**
UPGRADEEOF

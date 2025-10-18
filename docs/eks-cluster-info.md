# CloudMart EKS Cluster Information

## Cluster Details

**Cluster Name:** cloudmart-dev
**Cluster Version:** 1.28
**Region:** eu-central-1
**Status:** ACTIVE ✓
**Created:** $(date +"%Y-%m-%d %H:%M:%S")

## Current State

✅ **Deployed:**
- EKS Control Plane
- KMS encryption for secrets
- CloudWatch Logs
- OIDC provider
- VPC CNI add-on
- kube-proxy add-on

⏸️ **Pending (requires node groups):**
- Worker nodes
- CoreDNS add-on
- EBS CSI Driver add-on
- IRSA service account roles

## Access Configuration

### kubectl Setup
```bash
# Configure kubectl
aws eks update-kubeconfig \
  --name cloudmart-dev \
  --region eu-central-1 \
  --alias cloudmart-dev

# Or use the convenience script
cd ~/GitHub/CloudMart/scripts
./configure-kubectl.sh

# Verify access
kubectl cluster-info
kubectl get namespaces
```

### API Endpoint
```bash
# Get cluster endpoint
aws eks describe-cluster --name cloudmart-dev \
  --query 'cluster.endpoint' --output text
```

## Cluster Configuration

### Security

- ✅ **Secrets Encryption:** Customer-managed KMS key with rotation
- ✅ **Control Plane Logs:** All 5 log types enabled
- ✅ **Private Endpoint:** Enabled
- ✅ **Public Endpoint:** Enabled (⚠️ Restrict in production)
- ✅ **OIDC Provider:** Configured for IRSA

### Logging

**Enabled log types:**
- API Server
- Audit
- Authenticator
- Controller Manager
- Scheduler

**Log Group:** `/aws/eks/cloudmart-dev/cluster`
**Retention:** 7 days
**Encryption:** KMS

### Add-ons Status

| Add-on | Status | Notes |
|--------|--------|-------|
| vpc-cni | Active | Pod networking ready |
| kube-proxy | Active | Service routing ready |
| coredns | Not deployed ⏸️ | Will be added in Step 2.3 |
| aws-ebs-csi-driver | Not deployed ⏸️ | Will be added in Step 2.3 |

## OIDC Provider for IRSA

**Status:** ✅ Configured

The OIDC provider is ready for IRSA (IAM Roles for Service Accounts). Service account roles will be created in Step 2.3 after node groups are deployed.
```bash
# View OIDC provider
aws eks describe-cluster --name cloudmart-dev \
  --query 'cluster.identity.oidc.issuer' --output text

# List OIDC providers
aws iam list-open-id-connect-providers
```

## Verification Commands
```bash
# Check cluster status
aws eks describe-cluster --name cloudmart-dev \
  --query 'cluster.status'

# List add-ons
aws eks list-addons --cluster-name cloudmart-dev

# View logs
aws logs tail /aws/eks/cloudmart-dev/cluster --follow

# Check encryption
aws eks describe-cluster --name cloudmart-dev \
  --query 'cluster.encryptionConfig'

# View cluster info
kubectl cluster-info
kubectl get all -A
```

## Current Limitations

⚠️ **No Worker Nodes Yet**
- Cannot schedule pods
- Some system components pending
- Node groups will be created in Step 2.2

⚠️ **CoreDNS Not Available**
- DNS resolution not yet functional
- Will be deployed after node groups

⚠️ **IRSA Roles Not Created**
- OIDC provider exists
- Service account roles will be created in Step 2.3

## Cost Summary

**Monthly Costs (Current):**
- EKS Control Plane: $73.00
- KMS Key: $1.00
- CloudWatch Logs: ~$1.00
- VPC (NAT Gateway, etc.): ~$32.00
- **Total:** ~$107/month

**Note:** Worker nodes will add ~$60-150/month in Step 2.2

## Next Steps

1. ✅ **Step 2.1:** EKS cluster created
2. ⏭️ **Step 2.2:** Create EKS node groups
3. ⏭️ **Step 2.3:** Deploy CoreDNS, EBS CSI, and IRSA roles
4. ⏭️ **Step 2.4:** Install AWS Load Balancer Controller

## Troubleshooting

### kubectl cannot connect
```bash
# Reconfigure kubeconfig
aws eks update-kubeconfig --name cloudmart-dev --region eu-central-1

# Verify AWS credentials
aws sts get-caller-identity

# Check cluster exists
aws eks describe-cluster --name cloudmart-dev
```

### Add-ons show UPDATE_AVAILABLE

This is expected before node groups are created. Add-ons will update automatically when nodes join the cluster.

---

**Status:** ✅ EKS cluster operational, ready for node groups
**Last Updated:** $(date +"%Y-%m-%d %H:%M:%S")
**Next:** Step 2.2 - Create EKS Node Groups

---

## Node Groups (Updated)

### On-Demand Node Group

**Configuration:**
- Instance Type: t3.medium
- Capacity: Min 2, Max 5, Desired 2
- Subnets: Private subnets across multiple AZs
- Labels: `nodegroup-type=on-demand`, `instance-lifecycle=on-demand`
- Taints: None

**Usage:**
```yaml
# All pods schedule here by default
spec:
  containers:
  - name: app
    image: myapp:latest
```

### Spot Node Group (Optional)

**Configuration:**
- Instance Types: t3.medium, t3a.medium, t2.medium (mixed)
- Capacity: Min 0, Max 3, Desired 0
- Subnets: Private subnets across multiple AZs
- Labels: `nodegroup-type=spot`, `instance-lifecycle=spot`
- Taints: `spot=true:NoSchedule`

**Usage:**
```yaml
# Pods must explicitly tolerate spot nodes
spec:
  tolerations:
  - key: "spot"
    operator: "Equal"
    value: "true"
    effect: "NoSchedule"
  nodeSelector:
    nodegroup-type: spot
  containers:
  - name: batch-job
    image: batch:latest
```

## Cost Breakdown (Updated)

**Monthly Costs:**
- EKS Control Plane: $73.00
- KMS Keys: $2.00
- CloudWatch Logs: ~$2.00
- VPC (NAT Gateway): ~$32.00
- **On-Demand Nodes (2x t3.medium):** ~$60.00
- Spot Nodes (when scaled up): ~$9/node/month
- **Total (with 2 on-demand nodes):** ~$169/month

**Cost optimization tip:** Use spot nodes for batch jobs, CI/CD, and non-critical workloads to save up to 70%.

## Verification Commands (Updated)
```bash
# List node groups
aws eks list-nodegroups --cluster-name cloudmart-dev

# Describe node group
aws eks describe-nodegroup \
  --cluster-name cloudmart-dev \
  --nodegroup-name cloudmart-dev-ondemand

# View nodes
kubectl get nodes
kubectl get nodes -o wide
kubectl describe nodes

# Check node labels
kubectl get nodes --show-labels

# View system pods (should all be running now)
kubectl get pods -n kube-system

# Check node capacity
kubectl top nodes

# Run verification script
cd ~/GitHub/CloudMart/scripts
./verify-nodes.sh
```

## Current Status (Updated)

✅ **Operational:**
- EKS Control Plane
- OIDC Provider
- 2 Worker Nodes (on-demand)
- VPC CNI
- kube-proxy
- kubectl configured

⏭️ **Next Steps:**
- Deploy CoreDNS add-on (Step 2.3)
- Deploy EBS CSI Driver (Step 2.3)
- Create IRSA service account roles (Step 2.3)
- Install AWS Load Balancer Controller (Step 2.4)

---
**Last Updated:** $(date +"%Y-%m-%d %H:%M:%S")

---

## Step 2.3: Add-ons & IRSA Complete

### EKS Managed Add-ons

✅ **CoreDNS**
- Version: Latest compatible with 1.31
- Status: Active
- Pods: 2 replicas
- Function: DNS resolution for services

✅ **EBS CSI Driver**
- Version: Latest compatible with 1.31
- Status: Active with IRSA
- Function: Persistent volume provisioning

### Kubernetes Components

✅ **Metrics Server**
- Provides resource metrics for HPA and monitoring
- Commands: `kubectl top nodes`, `kubectl top pods`

✅ **AWS Load Balancer Controller**
- Version: v2.7.0
- Manages ALB and NLB for Ingress resources
- IRSA Role: Configured

### IRSA Service Account Roles

All IAM roles created with proper OIDC trust relationships:

1. **Frontend SA:** `cloudmart-frontend-sa`
   - Permissions: CloudWatch Logs
   - Namespace: cloudmart-dev

2. **API SA:** `cloudmart-api-sa`
   - Permissions: Parameter Store, Secrets Manager, CloudWatch Logs
   - Namespace: cloudmart-dev

3. **Worker SA:** `cloudmart-worker-sa`
   - Permissions: Parameter Store, Secrets Manager, CloudWatch Logs, SES
   - Namespace: cloudmart-dev

4. **AWS LB Controller SA:** `aws-load-balancer-controller`
   - Permissions: Full ALB/NLB management
   - Namespace: kube-system

5. **EBS CSI Driver SA:** `ebs-csi-controller-sa`
   - Permissions: EBS volume management
   - Namespace: kube-system

### Using IRSA in Deployments

Example deployment with IRSA:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: cloudmart-api
  namespace: cloudmart-dev
spec:
  template:
    spec:
      serviceAccountName: cloudmart-api-sa
      containers:
      - name: api
        image: myapi:latest
        # Pod automatically gets IAM credentials via IRSA
```

### Verification Commands
```bash
# Check all add-ons
aws eks list-addons --cluster-name cloudmart-dev

# View CoreDNS
kubectl get pods -n kube-system -l k8s-app=kube-dns

# View EBS CSI Driver
kubectl get pods -n kube-system -l app.kubernetes.io/name=aws-ebs-csi-driver

# Check metrics
kubectl top nodes
kubectl top pods -A

# View AWS Load Balancer Controller
kubectl get deployment aws-load-balancer-controller -n kube-system

# View service accounts
kubectl get sa -n cloudmart-dev

# Verify IRSA annotation
kubectl describe sa cloudmart-api-sa -n cloudmart-dev

# Run verification script
cd ~/GitHub/CloudMart/scripts
./verify-addons.sh
```

### Storage Classes

Default storage class for EBS volumes:
```bash
kubectl get storageclass
```

Available: `gp2`, `gp3` (recommended), `io1`, `io2`

### Next Steps

✅ Phase 1: VPC, Security Groups, IAM
✅ Step 2.1: EKS Cluster
✅ Step 2.2: Node Groups
✅ Step 2.3: Add-ons & IRSA
⏭️ Step 2.4: Application Deployment Setup

---
**Step 2.3 Complete:** $(date +"%Y-%m-%d %H:%M:%S")

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

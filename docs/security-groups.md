# CloudMart Security Groups Documentation

## Overview

This document provides a comprehensive overview of all security groups implemented in the CloudMart infrastructure, their purposes, rules, and security justifications.

**Last Updated:** $(date +"%Y-%m-%d")

## Security Architecture Principles

1. **Least Privilege Access:** Each component has only the minimum required network access
2. **Defense in Depth:** Multiple security layers (NACLs, Security Groups, IAM policies)
3. **Zero Trust Network:** No implicit trust between components
4. **Network Segmentation:** Clear separation between public, application, and data tiers
5. **Explicit Allow Model:** All traffic is denied by default; only explicitly allowed traffic is permitted

## Network Topology
```
┌─────────────────────────────────────────────────────────────────┐
│                         Internet                                 │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     │ HTTP (80), HTTPS (443)
                     │
┌────────────────────▼────────────────────────────────────────────┐
│               Application Load Balancer (ALB)                    │
│                    Security Group: alb-sg                        │
│   Ingress: 0.0.0.0/0 → 80, 443                                 │
│   Egress:  → EKS Nodes (all TCP)                               │
└────────────────────┬────────────────────────────────────────────┘
                     │
                     │ All TCP ports
                     │
┌────────────────────▼────────────────────────────────────────────┐
│                    EKS Worker Nodes                              │
│              Security Group: eks-nodes-sg                        │
│   Ingress: ALB → all TCP                                        │
│            EKS CP → 443, 10250                                  │
│            Self → all protocols (inter-node)                    │
│   Egress:  → 0.0.0.0/0 (all traffic)                           │
└──────┬─────────────────────────────────────┬───────────────────┘
       │                                     │
       │ PostgreSQL (5432)                   │ Redis (6379)
       │                                     │
┌──────▼──────────────────┐     ┌───────────▼──────────────────┐
│   RDS PostgreSQL        │     │   ElastiCache Redis          │
│   Security Group:       │     │   Security Group:            │
│   rds-sg                │     │   elasticache-sg             │
│                         │     │                              │
│   Ingress: EKS → 5432   │     │   Ingress: EKS → 6379       │
│   Egress:  Minimal      │     │   Egress:  Minimal          │
└─────────────────────────┘     └──────────────────────────────┘
```

## Security Group Inventory

### 1. ALB Security Group (`cloudmart-dev-alb-sg`)

**Purpose:** Public-facing Application Load Balancer for HTTP/HTTPS traffic routing

**Component:** Load Balancer Tier

**Ingress Rules:**

| Protocol | Port | Source | Description | Justification |
|----------|------|--------|-------------|---------------|
| TCP | 80 | 0.0.0.0/0 | HTTP from internet | Public web application access |
| TCP | 443 | 0.0.0.0/0 | HTTPS from internet | Secure public web application access |

**Egress Rules:**

| Protocol | Port Range | Destination | Description | Justification |
|----------|------------|-------------|-------------|---------------|
| TCP | 0-65535 | eks-nodes-sg | All traffic to EKS nodes | Forward requests to application tier |

**Security Considerations:**
- ✅ Only ports 80 and 443 exposed to internet
- ✅ Egress restricted to EKS nodes security group only
- ✅ No direct database or cache access
- ⚠️ Consider implementing WAF rules for additional protection

---

### 2. EKS Nodes Security Group (`cloudmart-dev-eks-nodes-sg`)

**Purpose:** Kubernetes worker nodes running containerized applications

**Component:** Application Tier

**Ingress Rules:**

| Protocol | Port Range | Source | Description | Justification |
|----------|------------|--------|-------------|---------------|
| TCP | 0-65535 | alb-sg | Traffic from ALB | Receive routed HTTP/HTTPS requests |
| All | All | eks-nodes-sg (self) | Inter-node communication | Pod-to-pod networking, kube-proxy, kubelet |
| TCP | 443 | eks-cp-sg | HTTPS from control plane | Kubernetes API communication |
| TCP | 10250 | eks-cp-sg | Kubelet from control plane | Node management and metrics |

**Egress Rules:**

| Protocol | Port | Destination | Description | Justification |
|----------|------|-------------|-------------|---------------|
| All | All | 0.0.0.0/0 | All outbound traffic | ECR image pulls, AWS API calls, external services |

**Security Considerations:**
- ✅ Inter-node communication limited to same security group
- ✅ Control plane access properly scoped
- ✅ No direct inbound from internet
- ⚠️ Egress is permissive (required for container operations)
- 💡 Consider using VPC endpoints to reduce internet egress

---

### 3. EKS Control Plane Security Group (`cloudmart-dev-eks-cp-sg`)

**Purpose:** Managed Kubernetes control plane (API server, etcd, scheduler)

**Component:** Control Plane Tier (AWS Managed)

**Ingress Rules:**

| Protocol | Port | Source | Description | Justification |
|----------|------|--------|-------------|---------------|
| TCP | 443 | eks-nodes-sg | HTTPS from worker nodes | kubectl commands, node registration |

**Egress Rules:**

| Protocol | Port Range | Destination | Description | Justification |
|----------|------------|-------------|-------------|---------------|
| TCP | 0-65535 | eks-nodes-sg | Traffic to worker nodes | Kubelet communication, pod logs, exec commands |

**Security Considerations:**
- ✅ Only accessible from worker nodes
- ✅ Managed by AWS (patching, updates)
- ✅ No public access to API server endpoint

---

### 4. RDS Security Group (`cloudmart-dev-rds-sg`)

**Purpose:** PostgreSQL database for persistent application data

**Component:** Data Tier

**Ingress Rules:**

| Protocol | Port | Source | Description | Justification |
|----------|------|--------|-------------|---------------|
| TCP | 5432 | eks-nodes-sg | PostgreSQL from EKS nodes | Application database access |

**Egress Rules:**

| Protocol | Port | Destination | Description | Justification |
|----------|------|-------------|-------------|---------------|
| TCP | 443 | 0.0.0.0/0 | HTTPS for AWS services | CloudWatch metrics, backup verification |

**Security Considerations:**
- ✅ No public access
- ✅ Only accessible from application tier
- ✅ Single port exposure (5432)
- ✅ Minimal egress (service communication only)
- 💡 Consider database-level encryption and access controls

---

### 5. ElastiCache Security Group (`cloudmart-dev-elasticache-sg`)

**Purpose:** Redis cache cluster for session storage and application caching

**Component:** Data Tier

**Ingress Rules:**

| Protocol | Port | Source | Description | Justification |
|----------|------|--------|-------------|---------------|
| TCP | 6379 | eks-nodes-sg | Redis from EKS nodes | Cache access from applications |

**Egress Rules:**

| Protocol | Port | Destination | Description | Justification |
|----------|------|-------------|-------------|---------------|
| TCP | 443 | 0.0.0.0/0 | HTTPS for AWS services | CloudWatch metrics |

**Security Considerations:**
- ✅ No public access
- ✅ Only accessible from application tier
- ✅ Single port exposure (6379)
- ✅ Encryption in transit enabled (TLS)
- 💡 Consider Redis AUTH for additional authentication

---

### 6. Bastion Security Group (`cloudmart-dev-bastion-sg`) [Optional]

**Purpose:** Jump host for administrative access to private resources

**Component:** Management Tier

**Ingress Rules:**

| Protocol | Port | Source | Description | Justification |
|----------|------|--------|-------------|---------------|
| TCP | 22 | Specific CIDR(s) | SSH from admin IPs | Administrative access |

**Egress Rules:**

| Protocol | Port Range | Destination | Description | Justification |
|----------|------------|-------------|-------------|---------------|
| TCP | 22 | eks-nodes-sg | SSH to EKS nodes | Node troubleshooting |
| All | All | 0.0.0.0/0 | General internet | Package installation, updates |

**Security Considerations:**
- ⚠️ Disabled by default in dev environment
- ✅ SSH access restricted to specific IP addresses
- 💡 Consider AWS Systems Manager Session Manager instead (no bastion needed)
- 💡 Implement SSH key rotation policy
- 💡 Enable SSH audit logging

---

## Security Group Rules Matrix

| Source → Destination | ALB | EKS Nodes | EKS CP | RDS | ElastiCache |
|---------------------|-----|-----------|--------|-----|-------------|
| **Internet (0.0.0.0/0)** | ✅ 80,443 | ❌ | ❌ | ❌ | ❌ |
| **ALB** | - | ✅ All TCP | ❌ | ❌ | ❌ |
| **EKS Nodes** | ❌ | ✅ All | ✅ 443 | ✅ 5432 | ✅ 6379 |
| **EKS Control Plane** | ❌ | ✅ 443,10250 | - | ❌ | ❌ |
| **RDS** | ❌ | ❌ | ❌ | - | ❌ |
| **ElastiCache** | ❌ | ❌ | ❌ | ❌ | - |

**Legend:**
- ✅ = Allowed (with specified ports)
- ❌ = Denied
- \- = Not applicable

---

## Compliance Considerations

### GDPR / Data Protection
- ✅ Database and cache not accessible from internet
- ✅ Network segmentation prevents unauthorized data access
- ✅ Encryption in transit for all data tier communication

### PCI DSS (if handling payment data)
- ✅ Network segmentation (Requirement 1.2)
- ✅ Restrict inbound/outbound traffic (Requirement 1.2.1)
- ✅ Deny all by default (Requirement 1.2.3)
- ⚠️ Additional requirements for payment processing zones

### CIS AWS Foundations Benchmark
- ✅ Security groups restrict traffic (5.1, 5.2)
- ✅ No overly permissive rules (5.3)
- ✅ VPC Flow Logs enabled for monitoring (3.9)

---

## Security Best Practices Checklist

- [x] Least privilege access implemented
- [x] No unrestricted SSH access (0.0.0.0/0:22)
- [x] No unrestricted RDP access (0.0.0.0/0:3389)
- [x] Database ports not exposed to internet
- [x] Security group rules documented
- [x] Inter-tier communication restricted
- [x] Egress traffic monitored via VPC Flow Logs
- [x] Security groups have descriptive names and tags

---

## Monitoring and Alerting

### VPC Flow Logs
All security group traffic is captured by VPC Flow Logs:
- **Log Group:** `/aws/vpc/cloudmart-dev`
- **Retention:** 7 days
- **Traffic Type:** ALL (accepted and rejected)

### Recommended CloudWatch Alarms
1. **Rejected Traffic Spike:** Alert on unusual number of rejected connections
2. **Unauthorized Access Attempts:** Monitor SSH/RDP attempts from unknown IPs
3. **Database Connection Anomalies:** Alert on connections outside normal patterns

### Regular Audit Tasks
- [ ] Monthly review of security group rules
- [ ] Quarterly access pattern analysis from Flow Logs
- [ ] Annual security group optimization review
- [ ] Continuous monitoring with AWS GuardDuty

---

## Incident Response

### Suspected Compromise
1. **Isolate:** Remove affected security group from resources
2. **Analyze:** Review VPC Flow Logs for suspicious patterns
3. **Contain:** Create temporary security group with minimal access
4. **Remediate:** Patch vulnerabilities, rotate credentials
5. **Review:** Update security group rules based on findings

### Emergency Access Procedure
1. Use AWS Systems Manager Session Manager (no bastion required)
2. Enable MFA for all privileged operations
3. Document all emergency access in audit log
4. Revoke emergency access after incident resolution

---

## Maintenance

### Adding New Rules
1. Document business justification
2. Use most restrictive rule possible
3. Test in dev environment first
4. Update this documentation
5. Create Terraform code review
6. Apply to staging, then production

### Removing Rules
1. Verify rule is no longer needed
2. Check CloudWatch metrics for usage
3. Remove from dev first
4. Monitor for 48 hours
5. Remove from staging and production

---

## References

- [AWS Security Groups Documentation](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html)
- [EKS Security Best Practices](https://aws.github.io/aws-eks-best-practices/security/docs/)
- [CIS AWS Foundations Benchmark](https://www.cisecurity.org/benchmark/amazon_web_services)
- CloudMart Terraform Module: `terraform/modules/security-groups/`

---

## Terraform Code Reference

All security groups are managed as Infrastructure as Code:
```bash
# Location
terraform/modules/security-groups/

# Apply security groups
cd terraform/environments/dev
terraform apply

# View security group IDs
terraform output security_group_summary
```

---

**Document Owner:** CloudMart DevOps Team  
**Review Schedule:** Quarterly  
**Next Review:** $(date -d '+3 months' +"%Y-%m-%d")

# EKS Node Groups Module

This module creates managed EKS node groups with both on-demand and spot instances.

## Features

- **On-Demand Node Group:** Reliable worker nodes for critical workloads
- **Spot Node Group (Optional):** Cost-optimized nodes for fault-tolerant workloads
- **Launch Templates:** Custom configuration with IMDSv2, monitoring, and proper tagging
- **Auto-Scaling:** Automatic scaling based on resource demand
- **Multi-AZ:** Nodes distributed across availability zones
- **Cost Allocation:** Comprehensive tagging for billing and cost tracking

## Node Group Strategy

### On-Demand Nodes
- **Purpose:** Critical workloads, system components
- **Instance Type:** t3.medium (default)
- **Capacity:** 2-5 nodes (2 desired)
- **Labels:** `nodegroup-type=on-demand`
- **Taints:** None (accepts all pods)

### Spot Nodes (Optional)
- **Purpose:** Non-critical, fault-tolerant workloads
- **Instance Types:** Mixed (t3.medium, t3a.medium, t2.medium)
- **Capacity:** 0-3 nodes (0 desired by default)
- **Labels:** `nodegroup-type=spot`
- **Taints:** `spot=true:NoSchedule` (only pods with tolerance)

## Cost Optimization

**Spot instances** can provide up to 90% savings compared to on-demand:
- t3.medium on-demand: ~$0.0416/hour (~$30/month)
- t3.medium spot: ~$0.0125/hour (~$9/month)

**Estimated monthly costs** (2 on-demand nodes):
- ~$60/month for primary capacity

## Usage
```hcl
module "eks_node_groups" {
  source = "../../modules/eks-node-groups"

  project_name = "cloudmart"
  environment  = "dev"
  
  cluster_name                       = module.eks.cluster_id
  cluster_version                    = module.eks.cluster_version
  cluster_endpoint                   = module.eks.cluster_endpoint
  cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data
  
  node_role_arn           = module.iam.eks_node_group_role_arn
  node_security_group_id  = module.security_groups.eks_nodes_security_group_id
  private_subnet_ids      = module.vpc.private_subnet_ids
  
  # On-demand configuration
  ondemand_instance_types = ["t3.medium"]
  ondemand_min_size       = 2
  ondemand_max_size       = 5
  ondemand_desired_size   = 2
  
  # Spot configuration (optional)
  enable_spot_node_group = true
  spot_instance_types    = ["t3.medium", "t3a.medium"]
  spot_min_size          = 0
  spot_max_size          = 3
  spot_desired_size      = 0
  
  cost_center = "CloudMart-Development"
  
  common_tags = {
    Project   = "CloudMart"
    ManagedBy = "Terraform"
  }
}
```

## Scheduling Workloads

### On-Demand Nodes
No special configuration needed - pods schedule automatically.

### Spot Nodes
Pods must tolerate the spot taint:
```yaml
tolerations:
- key: "spot"
  operator: "Equal"
  value: "true"
  effect: "NoSchedule"
nodeSelector:
  nodegroup-type: spot
```

## Tagging Strategy

All resources include:
- **Project:** CloudMart
- **Environment:** dev/staging/prod
- **ManagedBy:** Terraform
- **CostCenter:** For billing allocation
- **NodeGroup:** on-demand or spot
- **Cluster Autoscaler tags:** For automatic scaling

## Security

- ✅ IMDSv2 enforced (no IMDSv1)
- ✅ Nodes in private subnets only
- ✅ Monitoring enabled
- ✅ Proper IAM roles with least privilege
- ✅ Security groups restrict traffic

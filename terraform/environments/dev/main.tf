# CloudMart Development Environment

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket  = "cloudmart-terraform-state-804"
    key     = "dev/terraform.tfstate"
    region  = "eu-central-1"
    encrypt = true

    dynamodb_table = "cloudmart-terraform-lock"
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "CloudMart"
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}

# VPC Module
module "vpc" {
  source = "../../modules/vpc"

  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones

  enable_nat_gateway = true
  single_nat_gateway = true
  enable_flow_logs   = true

  common_tags = var.common_tags
}

# Security Groups Module
module "security_groups" {
  source = "../../modules/security-groups"

  project_name = var.project_name
  environment  = var.environment
  vpc_id       = module.vpc.vpc_id

  enable_bastion_sg     = false
  bastion_allowed_cidrs = []

  common_tags = var.common_tags

  depends_on = [module.vpc]
}

# IAM Module
module "iam" {
  source = "../../modules/iam"

  project_name = var.project_name
  environment  = var.environment

  # IRSA disabled until EKS cluster is created
  enable_irsa             = false
  eks_oidc_provider_arn   = ""
  eks_oidc_provider       = ""
  kubernetes_namespace    = "${var.project_name}-${var.environment}"

  common_tags = var.common_tags

  depends_on = [module.vpc]
}

# EKS Cluster Module
module "eks" {
  source = "../../modules/eks"

  project_name = var.project_name
  environment  = var.environment

  cluster_version  = var.eks_cluster_version
  cluster_role_arn = module.iam.eks_cluster_role_arn

  private_subnet_ids        = module.vpc.private_subnet_ids
  public_subnet_ids         = module.vpc.public_subnet_ids
  cluster_security_group_id = module.security_groups.eks_control_plane_security_group_id

  # Endpoint configuration
  cluster_endpoint_private_access      = true
  cluster_endpoint_public_access       = true
  cluster_endpoint_public_access_cidrs = ["0.0.0.0/0"]  # Restrict in production

  # Enable comprehensive logging
  enabled_cluster_log_types  = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cluster_log_retention_days = 7

  common_tags = var.common_tags

  depends_on = [
    module.vpc,
    module.security_groups,
    module.iam
  ]
}

# EKS Node Groups Module
module "eks_node_groups" {
  source = "../../modules/eks-node-groups"

  project_name = var.project_name
  environment  = var.environment

  cluster_name                       = module.eks.cluster_id
  cluster_version                    = module.eks.cluster_version
  cluster_endpoint                   = module.eks.cluster_endpoint
  cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data

  node_role_arn          = module.iam.eks_node_group_role_arn
  node_security_group_id = module.security_groups.eks_nodes_security_group_id
  private_subnet_ids     = module.vpc.private_subnet_ids

  # On-demand node group configuration
  ondemand_instance_types = var.ondemand_instance_types
  ondemand_min_size       = var.ondemand_min_size
  ondemand_max_size       = var.ondemand_max_size
  ondemand_desired_size   = var.ondemand_desired_size

  # Spot node group configuration (optional)
  enable_spot_node_group = var.enable_spot_node_group
  spot_instance_types    = var.spot_instance_types
  spot_min_size          = var.spot_min_size
  spot_max_size          = var.spot_max_size
  spot_desired_size      = var.spot_desired_size

  cost_center = var.cost_center
  common_tags = var.common_tags

  depends_on = [
    module.eks,
    module.iam,
    module.security_groups
  ]
}

# EKS Add-ons Module (Post Node Groups)
module "eks_addons" {
  source = "../../modules/eks-addons"

  project_name = var.project_name
  environment  = var.environment
  cluster_name = module.eks.cluster_id

  oidc_provider_arn = module.eks.oidc_provider_arn
  oidc_provider     = module.eks.oidc_provider

  parameter_store_policy_arn = module.iam.parameter_store_policy_arn
  secrets_manager_policy_arn = module.iam.secrets_manager_policy_arn

  kubernetes_namespace = "${var.project_name}-${var.environment}"

  enable_cluster_autoscaler = var.enable_cluster_autoscaler

  common_tags = var.common_tags

  depends_on = [
    module.eks,
    module.eks_node_groups
  ]
}

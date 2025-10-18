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

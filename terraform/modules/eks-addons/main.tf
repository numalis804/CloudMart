# EKS Add-ons Module - Post Node Groups
# Deploys add-ons that require worker nodes and creates IRSA roles

# Data sources
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
data "aws_partition" "current" {}

# ============================================================================
# EKS Managed Add-ons
# ============================================================================

# CoreDNS Add-on (requires worker nodes)
resource "aws_eks_addon" "coredns" {
  cluster_name                = var.cluster_name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  tags = var.common_tags
}

# EBS CSI Driver Add-on with IRSA
resource "aws_eks_addon" "ebs_csi_driver" {
  cluster_name             = var.cluster_name
  addon_name               = "aws-ebs-csi-driver"
  service_account_role_arn = aws_iam_role.ebs_csi_driver.arn
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"

  tags = var.common_tags

  depends_on = [aws_iam_role.ebs_csi_driver]
}

# ============================================================================
# IRSA Roles for EBS CSI Driver
# ============================================================================

# IAM Role for EBS CSI Driver
resource "aws_iam_role" "ebs_csi_driver" {
  name               = "${var.project_name}-${var.environment}-ebs-csi-driver-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${var.oidc_provider}:sub" : "system:serviceaccount:kube-system:ebs-csi-controller-sa"
            "${var.oidc_provider}:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-ebs-csi-driver-role"
      IRSA = "true"
    }
  )
}

# Attach AWS managed policy for EBS CSI Driver
resource "aws_iam_role_policy_attachment" "ebs_csi_driver" {
  role       = aws_iam_role.ebs_csi_driver.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
}

# ============================================================================
# IRSA Roles for CloudMart Applications
# ============================================================================

# Frontend Service Account Role
resource "aws_iam_role" "frontend_sa" {
  name = "${var.project_name}-${var.environment}-frontend-sa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${var.oidc_provider}:sub" : "system:serviceaccount:${var.kubernetes_namespace}:cloudmart-frontend-sa"
            "${var.oidc_provider}:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-frontend-sa-role"
      IRSA = "true"
      App  = "frontend"
    }
  )
}

# Frontend CloudWatch Logs policy
resource "aws_iam_role_policy" "frontend_cloudwatch" {
  name = "cloudwatch-logs"
  role = aws_iam_role.frontend_sa.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/eks/${var.cluster_name}/frontend/*"
      }
    ]
  })
}

# API Service Account Role
resource "aws_iam_role" "api_sa" {
  name = "${var.project_name}-${var.environment}-api-sa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${var.oidc_provider}:sub" : "system:serviceaccount:${var.kubernetes_namespace}:cloudmart-api-sa"
            "${var.oidc_provider}:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-api-sa-role"
      IRSA = "true"
      App  = "api"
    }
  )
}

# API policies
resource "aws_iam_role_policy_attachment" "api_parameter_store" {
  role       = aws_iam_role.api_sa.name
  policy_arn = var.parameter_store_policy_arn
}

resource "aws_iam_role_policy_attachment" "api_secrets_manager" {
  role       = aws_iam_role.api_sa.name
  policy_arn = var.secrets_manager_policy_arn
}

resource "aws_iam_role_policy" "api_cloudwatch" {
  name = "cloudwatch-logs"
  role = aws_iam_role.api_sa.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/eks/${var.cluster_name}/api/*"
      }
    ]
  })
}

# Worker Service Account Role
resource "aws_iam_role" "worker_sa" {
  name = "${var.project_name}-${var.environment}-worker-sa-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${var.oidc_provider}:sub" : "system:serviceaccount:${var.kubernetes_namespace}:cloudmart-worker-sa"
            "${var.oidc_provider}:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-worker-sa-role"
      IRSA = "true"
      App  = "worker"
    }
  )
}

# Worker policies
resource "aws_iam_role_policy_attachment" "worker_parameter_store" {
  role       = aws_iam_role.worker_sa.name
  policy_arn = var.parameter_store_policy_arn
}

resource "aws_iam_role_policy_attachment" "worker_secrets_manager" {
  role       = aws_iam_role.worker_sa.name
  policy_arn = var.secrets_manager_policy_arn
}

resource "aws_iam_role_policy" "worker_cloudwatch" {
  name = "cloudwatch-logs"
  role = aws_iam_role.worker_sa.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:${data.aws_partition.current.partition}:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:/aws/eks/${var.cluster_name}/worker/*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "worker_ses" {
  name = "ses-send-email"
  role = aws_iam_role.worker_sa.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ses:SendEmail",
          "ses:SendRawEmail"
        ]
        Resource = "*"
      }
    ]
  })
}

# ============================================================================
# IRSA Role for AWS Load Balancer Controller
# ============================================================================

resource "aws_iam_role" "aws_load_balancer_controller" {
  name = "${var.project_name}-${var.environment}-aws-lb-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${var.oidc_provider}:sub" : "system:serviceaccount:kube-system:aws-load-balancer-controller"
            "${var.oidc_provider}:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-aws-lb-controller-role"
      IRSA = "true"
    }
  )
}

# AWS Load Balancer Controller IAM Policy
resource "aws_iam_policy" "aws_load_balancer_controller" {
  name        = "${var.project_name}-${var.environment}-aws-lb-controller-policy"
  description = "IAM policy for AWS Load Balancer Controller"

  policy = file("${path.module}/alb-controller-policy.json")

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "aws_load_balancer_controller" {
  role       = aws_iam_role.aws_load_balancer_controller.name
  policy_arn = aws_iam_policy.aws_load_balancer_controller.arn
}

# ============================================================================
# IRSA Role for Cluster Autoscaler (Optional)
# ============================================================================

resource "aws_iam_role" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0
  name  = "${var.project_name}-${var.environment}-cluster-autoscaler-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = var.oidc_provider_arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "${var.oidc_provider}:sub" : "system:serviceaccount:kube-system:cluster-autoscaler"
            "${var.oidc_provider}:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-${var.environment}-cluster-autoscaler-role"
      IRSA = "true"
    }
  )
}

resource "aws_iam_role_policy" "cluster_autoscaler" {
  count = var.enable_cluster_autoscaler ? 1 : 0
  name  = "cluster-autoscaler"
  role  = aws_iam_role.cluster_autoscaler[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "autoscaling:DescribeAutoScalingGroups",
          "autoscaling:DescribeAutoScalingInstances",
          "autoscaling:DescribeLaunchConfigurations",
          "autoscaling:DescribeScalingActivities",
          "autoscaling:DescribeTags",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeLaunchTemplateVersions"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "autoscaling:SetDesiredCapacity",
          "autoscaling:TerminateInstanceInAutoScalingGroup",
          "ec2:DescribeImages",
          "ec2:GetInstanceTypesFromInstanceRequirements",
          "eks:DescribeNodegroup"
        ]
        Resource = "*"
      }
    ]
  })
}
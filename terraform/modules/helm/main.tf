resource "aws_iam_role" "this" {
  count = var.create_iam_role ? 1 : 0

  name        = "${local.iam_role_name}-role"
  description = "IAM role for ${var.release_name} in cluster ${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/oidc.eks.${data.aws_region.current.name}.amazonaws.com/id/${local.oidc}"
        }
        Condition = {
          StringEquals = {
            "oidc.eks.${data.aws_region.current.name}.amazonaws.com/id/${local.oidc}:sub" : "system:serviceaccount:${var.namespace}:${var.service_account_name}",
            "oidc.eks.${data.aws_region.current.name}.amazonaws.com/id/${local.oidc}:aud" = "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, {
    Name        = "${local.iam_role_name}-role"
    Environment = var.environment
  })
}

resource "aws_iam_policy" "this" {
  count = local.create_custom_policy ? 1 : 0

  name        = "${local.iam_role_name}-policy"
  description = "Custom IAM policy for ${var.release_name} in cluster ${var.cluster_name}"
  policy      = local.policy_document

  tags = merge(var.tags, {
    Name        = "${local.iam_role_name}-policy"
    Environment = var.environment
  })
}

resource "aws_iam_role_policy_attachment" "custom" {
  count = local.create_custom_policy ? 1 : 0

  role       = aws_iam_role.this[0].name
  policy_arn = aws_iam_policy.this[0].arn
}

resource "aws_iam_role_policy_attachment" "managed" {
  for_each = var.created_managed_policies ? toset(var.iam_policy_arns) : []

  role       = var.managed_role
  policy_arn = each.value
}

resource "kubernet_service_account" "this" {
  count = var.create_service_account ? 1 : 0

  metadata {
    name      = var.service_account_name
    namespace = var.namespace
    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.this[0].arn
    }
  }
}

resource "helm_release" "this" {
  count = var.create_helm_release ? 1 : 0

  name             = var.release_name
  repository       = var.chart_repository
  chart            = var.chart_name
  version          = var.chart_version
  namespace        = var.namespace
  create_namespace = var.create_namespace

  dynamic "set" {
    for_each = var.helm_set_values
    content {
      name  = set.key
      value = set.value
    }
  }

  depends_on = [
    kubernet_service_account.this,
    aws_iam_role_policy_attachment.custom,
    aws_iam_role_policy_attachment.managed
  ]
}
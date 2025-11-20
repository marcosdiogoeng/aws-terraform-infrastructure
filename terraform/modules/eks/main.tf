resource "aws_eks_cluster" "this" {
  name = "${var.project_name}-cluster"

  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.32"
  enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  vpc_config {
    endpoint_private_access = true
    endpoint_public_access  = true

    subnet_ids = toset(var.public_subnets)
  }


  tags = merge(var.tags, {
    Name = "${var.project_name}-cluster"
  })

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_role_attachment
  ]
}

resource "aws_iam_role" "eks_cluster_role" {
  name = "${var.project_name}-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })

  tags = merge(var.tags, {
    Name = "${var.project_name}-cluster-role"
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_role_attachment" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_openid_connect_provider" "this" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = data.tls_certificate.eks_certificate_oidc.certificates[*].sha1_fingerprint
  url             = data.tls_certificate.eks_certificate_oidc.url
  tags = merge(var.tags, {
    Name = "${var.project_name}-oidc"
  })
}

resource "aws_security_group_rule" "eks_cluster_sg_rule" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_eks_cluster.this.vpc_config[0].cluster_security_group_id
}
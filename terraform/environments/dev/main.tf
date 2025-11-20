module "vpc" {
  source   = "../../modules/vpc"
  vpc_cidr = var.cidr_block
  tags     = local.tags
}

module "eks" {
  source         = "../../modules/eks"
  tags           = local.tags
  project_name   = var.project_name
  public_subnets = module.vpc.public_subnets
}

module "nodes" {
  source          = "../../modules/nodes"
  tags            = local.tags
  project_name    = var.project_name
  environment     = var.environment
  private_subnets = module.vpc.private_subnets
  cluster_name    = module.eks.cluster_name
}

module "aws_load_balancer" {
  source                 = "../../modules/helm"
  environment            = var.environment
  oidc                   = module.eks.oidc
  cluster_name           = module.eks.cluster_name
  create_helm_release    = true
  release_name           = "aws-load-balancer-controller"
  chart_repository       = "https://aws.github.io/eks-charts"
  chart_name             = "aws-load-balancer-controller"
  chart_version          = "1.10.1"
  namespace              = "kube-system"
  iam_policy_json_file   = "../../modules/helm/policies/aws-load-balancer.json"
  create_iam_role        = true
  iam_role_name          = "aws-load-balancer-controller"
  create_service_account = true
  service_account_name   = "aws-load-balancer-controller"

  helm_values = {
    "clusterName"           = module.eks.cluster_name
    "serviceAccount.create" = "false"
    "serviceAccount.name"   = "aws-load-balancer-controller"
    "region"                = var.aws_region
    "vpcId"                 = module.vpc.vpc_id
  }

  tags = local.tags

  depends_on = [module.eks]
}

module "external_dns" {
  source                 = "../../modules/helm"
  environment            = var.environment
  oidc                   = module.eks.oidc
  cluster_name           = module.eks.cluster_name
  create_helm_release    = true
  release_name           = "external-dns"
  chart_repository       = "https://kubernetes-sigs.github.io/external-dns/"
  chart_name             = "external-dns"
  chart_version          = "1.15.2"
  namespace              = "kube-system"
  iam_policy_json_file   = "../../modules/helm/policies/external-dns.json"
  create_iam_role        = true
  iam_role_name          = "external-dns"
  create_service_account = true
  service_account_name   = "external-dns"

  helm_values = {
    "serviceAccount.create" = "false"
    "serviceAccount.name"   = "external-dns"
  }

  tags = local.tags

  depends_on = [module.eks]
}

module "external_secrets" {
  source                 = "../../modules/helm"
  environment            = var.environment
  oidc                   = module.eks.oidc
  cluster_name           = module.eks.cluster_name
  create_helm_release    = true
  release_name           = "external-secrets"
  chart_repository       = "https://charts.external-secrets.io"
  chart_name             = "external-secrets"
  chart_version          = "0.16.1"
  namespace              = "external-secrets"
  create_namespace       = true
  iam_policy_json_file   = "../../modules/helm/policies/external-secrets.json"
  create_iam_role        = true
  iam_role_name          = "external-secrets"
  create_service_account = true
  service_account_name   = "external-secrets"

  helm_values = {
    "serviceAccount.create"                                     = "false"
    "serviceAccount.name"                                       = "external-secrets"
    "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn" = module.external_secrets_iam_role.arn
  }

  tags = local.tags

  depends_on = [module.eks]
}

module "aws_ebs_csi" {
  source                   = "../../modules/helm"
  environment              = var.environment
  oidc                     = module.eks.oidc
  cluster_name             = module.eks.cluster_name
  create_helm_release      = true
  release_name             = "aws-ebs-csi-driver"
  chart_repository         = "https://kubernetes-sigs.github.io/aws-ebs-csi-driver"
  chart_name               = "aws-ebs-csi-driver"
  chart_version            = "2.41.0"
  namespace                = "kube-system"
  created_managed_policies = true
  managed_role             = module.nodes.managed_role_name
  iam_policy_arns          = ["arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"]

  tags = local.tags

  depends_on = [module.eks]
}

module "metrics_server" {
  source              = "../../modules/helm"
  environment         = var.environment
  oidc                = module.eks.oidc
  cluster_name        = module.eks.cluster_name
  create_helm_release = true
  release_name        = "metrics-server"
  chart_repository    = "https://kubernetes-sigs.github.io/metrics-server/"
  chart_name          = "metrics-server"
  chart_version       = "3.12.2"
  namespace           = "kube-system"

  helm_values = {
    "args" = "{--kubelet-insecure-tls}"
  }

  tags = local.tags

  depends_on = [module.eks]
}

module "k8s" {
  source = "../../modules/k8s"
  depends_on = [ 
    module.eks,
    module.external_secrets,
    module.aws_ebs_csi
   ]
}

module "vpn" {
  source = "../../modules/ec2"

  project_name        = "vpn"
  environment         = var.environment
  instance_name       = "firezone"
  instance_type       = "t4g.micro"
  ami_id              = data.aws_ssm_parameter.ubuntu[0].value
  vpc_id              = module.vpc.vpc_id
  subnet_id           = module.vpc.subnet_public_1a
  associate_public_ip = true
  attach_ssm_role     = true
  associate_eip       = false
  root_block_device = {
    volume_size = 20
    volume_type = "gp3"
  }

  security_group_rules = {
    ingress = [
      {
        description = "Allow TCP access"
        from_port   = 13000
        to_port     = 13000
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
      },
      {
        description = "Allow WireGuard access"
        from_port   = 51820
        to_port     = 51820
        protocol    = "udp"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ]
  }

  generate_key_pair = true
  store_key_in_s3   = true
  s3_bucket_name    = "ssh-keys-devlopes"
  s3_key_name       = "vpn-firezone-${var.environment}-key.pem"
  key_name          = "vpn-firezone-${var.environment}-key"

  tags = local.tags
}
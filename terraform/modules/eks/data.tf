data "tls_certificate" "eks_certificate_oidc" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}
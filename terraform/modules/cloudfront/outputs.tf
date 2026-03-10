output "distribution_id" {
  description = "ID da distribuição CloudFront."
  value       = aws_cloudfront_distribution.this.id
}

output "distribution_arn" {
  description = "ARN da distribuição CloudFront."
  value       = aws_cloudfront_distribution.this.arn
}

output "distribution_domain_name" {
  description = "Domínio da distribuição CloudFront (ex: d1234.cloudfront.net)."
  value       = aws_cloudfront_distribution.this.domain_name
}

output "distribution_hosted_zone_id" {
  description = "Hosted Zone ID do CloudFront — use para criar Alias records no Route53."
  value       = aws_cloudfront_distribution.this.hosted_zone_id
}

output "distribution_etag" {
  description = "ETag da distribuição (útil para invalidações)."
  value       = aws_cloudfront_distribution.this.etag
}

output "distribution_status" {
  description = "Status da distribuição: Deployed ou InProgress."
  value       = aws_cloudfront_distribution.this.status
}

output "oac_ids" {
  description = "Mapa de Origin Access Control IDs criados (origin_id → oac_id)."
  value       = { for k, v in aws_cloudfront_origin_access_control.this : k => v.id }
}

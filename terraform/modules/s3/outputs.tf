output "bucket_id" {
  description = "Nome/ID do bucket S3."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN do bucket S3."
  value       = aws_s3_bucket.this.arn
}

output "bucket_domain_name" {
  description = "Domínio do bucket (s3.amazonaws.com)."
  value       = aws_s3_bucket.this.bucket_domain_name
}

output "bucket_regional_domain_name" {
  description = "Domínio regional do bucket."
  value       = aws_s3_bucket.this.bucket_regional_domain_name
}

output "bucket_hosted_zone_id" {
  description = "Hosted Zone ID do bucket (útil para Route53)."
  value       = aws_s3_bucket.this.hosted_zone_id
}

output "website_endpoint" {
  description = "Endpoint do site estático (se habilitado)."
  value       = var.website_enabled ? aws_s3_bucket_website_configuration.this[0].website_endpoint : null
}

output "website_domain" {
  description = "Domínio do site estático (se habilitado)."
  value       = var.website_enabled ? aws_s3_bucket_website_configuration.this[0].website_domain : null
}

output "repository_arn" {
  description = "ARN do repositório ECR."
  value       = aws_ecr_repository.this.arn
}

output "repository_url" {
  description = "URL do repositório ECR (para docker push/pull)."
  value       = aws_ecr_repository.this.repository_url
}

output "repository_name" {
  description = "Nome do repositório ECR."
  value       = aws_ecr_repository.this.name
}

output "registry_id" {
  description = "ID do registry (Account ID da AWS)."
  value       = aws_ecr_repository.this.registry_id
}

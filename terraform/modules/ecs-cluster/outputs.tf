output "cluster_id" {
  description = "ID do cluster ECS"
  value       = aws_ecs_cluster.this.id
}

output "cluster_arn" {
  description = "ARN do cluster ECS"
  value       = aws_ecs_cluster.this.arn
}

output "cluster_name" {
  description = "Nome do cluster ECS"
  value       = aws_ecs_cluster.this.name
}

output "kms_key_arn" {
  description = "ARN da KMS key criada (null se create_kms_key = false)"
  value       = var.create_kms_key ? aws_kms_key.this[0].arn : null
}

output "exec_log_group_name" {
  description = "Nome do CloudWatch Log Group para ECS Exec (null se não criado)"
  value       = var.create_exec_log_group ? aws_cloudwatch_log_group.exec[0].name : null
}

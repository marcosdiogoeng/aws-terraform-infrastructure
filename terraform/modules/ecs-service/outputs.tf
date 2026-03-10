# ==============================================================================
# terraform-aws-ecs-service – Outputs
# ==============================================================================

output "service_id" {
  description = "ID do serviço ECS"
  value       = aws_ecs_service.this.id
}

output "service_name" {
  description = "Nome do serviço ECS"
  value       = aws_ecs_service.this.name
}

output "service_arn" {
  description = "ARN do serviço ECS"
  value       = aws_ecs_service.this.id # mesma coisa que o ID no ECS
}

output "task_definition_arn" {
  description = "ARN completo (com revisão) da task definition ativa"
  value       = aws_ecs_task_definition.this.arn
}

output "task_definition_family" {
  description = "Família da task definition"
  value       = aws_ecs_task_definition.this.family
}

output "task_definition_revision" {
  description = "Número de revisão da task definition"
  value       = aws_ecs_task_definition.this.revision
}

output "task_role_arn" {
  description = "ARN da task role (criada ou passada)"
  value       = local.task_role_arn
}

output "execution_role_arn" {
  description = "ARN da execution role (criada ou passada)"
  value       = local.execution_role_arn
}

output "log_group_names" {
  description = "Mapa container → nome do CloudWatch Log Group"
  value       = { for k, lg in aws_cloudwatch_log_group.container : k => lg.name }
}

output "autoscaling_target_resource_id" {
  description = "resource_id do autoscaling target (null se autoscaling desabilitado)"
  value       = var.autoscaling_enabled ? aws_appautoscaling_target.this[0].resource_id : null
}

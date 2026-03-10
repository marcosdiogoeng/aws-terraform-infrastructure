###############################################################################
# Outputs do Módulo ElastiCache Redis
###############################################################################

output "replication_group_id" {
  description = "ID do replication group"
  value       = aws_elasticache_replication_group.this.id
}

output "replication_group_arn" {
  description = "ARN do replication group"
  value       = aws_elasticache_replication_group.this.arn
}

# ── Endpoints ─────────────────────────────────────────────────────────────────

output "primary_endpoint_address" {
  description = "Endpoint primário (escrita). Usar para operações de escrita."
  value       = aws_elasticache_replication_group.this.primary_endpoint_address
}

output "reader_endpoint_address" {
  description = "Endpoint de leitura. Usar para operações de leitura (non-cluster mode)."
  value       = aws_elasticache_replication_group.this.reader_endpoint_address
}

output "cluster_enabled_endpoint" {
  description = "Endpoint do cluster Redis (apenas cluster mode enabled)"
  value       = var.cluster_mode_enabled ? aws_elasticache_replication_group.this.configuration_endpoint_address : null
}

output "port" {
  description = "Porta do Redis"
  value       = var.port
}

# Endpoint completo formatado host:port (útil para connection strings)
output "primary_connection_string" {
  description = "Connection string do endpoint primário (host:port)"
  value = var.cluster_mode_enabled ? (
    "${aws_elasticache_replication_group.this.configuration_endpoint_address}:${var.port}"
  ) : (
    "${aws_elasticache_replication_group.this.primary_endpoint_address}:${var.port}"
  )
}

output "reader_connection_string" {
  description = "Connection string do endpoint de leitura (host:port)"
  value = var.cluster_mode_enabled ? null : (
    "${aws_elasticache_replication_group.this.reader_endpoint_address}:${var.port}"
  )
}

# ── Rede / Segurança ──────────────────────────────────────────────────────────

output "security_group_id" {
  description = "ID do security group criado pelo módulo (null se create_security_group = false)"
  value       = var.create_security_group ? aws_security_group.this[0].id : null
}

output "subnet_group_name" {
  description = "Nome do subnet group"
  value       = aws_elasticache_subnet_group.this.name
}

output "parameter_group_name" {
  description = "Nome do parameter group usado"
  value       = var.create_parameter_group ? aws_elasticache_parameter_group.this[0].name : var.parameter_group_name
}

# ── CloudWatch Alarms ─────────────────────────────────────────────────────────

output "cloudwatch_alarm_cpu_arn" {
  description = "ARN do alarme de CPU"
  value       = var.create_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.cpu[0].arn : null
}

output "cloudwatch_alarm_memory_arn" {
  description = "ARN do alarme de memória"
  value       = var.create_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.memory[0].arn : null
}

output "cloudwatch_alarm_connections_arn" {
  description = "ARN do alarme de conexões"
  value       = var.create_cloudwatch_alarms ? aws_cloudwatch_metric_alarm.connections[0].arn : null
}

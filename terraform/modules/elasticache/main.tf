###############################################################################
# ElastiCache Redis - Reusable Module
# Suporta: Single Node, Replication Group e Cluster Mode Enabled
###############################################################################

locals {
  name_prefix = var.name_prefix != "" ? var.name_prefix : var.name

  # Tags padrão mescladas com tags customizadas
  common_tags = merge(
    {
      Name        = var.name
    },
    var.tags
  )
}

###############################################################################
# Security Group
###############################################################################

resource "aws_security_group" "this" {
  count = var.create_security_group ? 1 : 0

  name        = "${local.name_prefix}-redis-sg"
  description = "Security group para ElastiCache Redis - ${var.name}"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Redis from allowed security groups"
    from_port       = var.port
    to_port         = var.port
    protocol        = "tcp"
    security_groups = var.allowed_security_group_ids
  }

  dynamic "ingress" {
    for_each = length(var.allowed_cidr_blocks) > 0 ? [1] : []
    content {
      description = "Redis from allowed CIDRs"
      from_port   = var.port
      to_port     = var.port
      protocol    = "tcp"
      cidr_blocks = var.allowed_cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-redis-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

###############################################################################
# Subnet Group
###############################################################################

resource "aws_elasticache_subnet_group" "this" {
  name       = "${local.name_prefix}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = local.common_tags
}

###############################################################################
# Parameter Group
###############################################################################

resource "aws_elasticache_parameter_group" "this" {
  count = var.create_parameter_group ? 1 : 0

  name        = "${local.name_prefix}-params"
  family      = var.parameter_group_family
  description = "Parameter group para ${var.name}"

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name  = parameter.value.name
      value = parameter.value.value
    }
  }

  # Parâmetros obrigatórios para cluster mode
  dynamic "parameter" {
    for_each = var.cluster_mode_enabled ? [1] : []
    content {
      name  = "cluster-enabled"
      value = "yes"
    }
  }

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

###############################################################################
# Replication Group (Single Node ou Multi-AZ)
###############################################################################

resource "aws_elasticache_replication_group" "this" {
  replication_group_id = local.name_prefix
  description          = var.description

  # Engine
  engine               = "redis"
  engine_version       = var.engine_version
  node_type            = var.node_type
  port                 = var.port

  # Topologia
  num_cache_clusters         = var.cluster_mode_enabled ? null : var.num_cache_nodes
  num_node_groups            = var.cluster_mode_enabled ? var.num_node_groups : null
  replicas_per_node_group    = var.cluster_mode_enabled ? var.replicas_per_node_group : null

  # Multi-AZ
  multi_az_enabled           = var.multi_az_enabled
  automatic_failover_enabled = var.multi_az_enabled || var.automatic_failover_enabled || var.cluster_mode_enabled

  # Rede
  subnet_group_name  = aws_elasticache_subnet_group.this.name
  security_group_ids = var.create_security_group ? [aws_security_group.this[0].id] : var.security_group_ids

  # Parameter Group
  parameter_group_name = var.create_parameter_group ? aws_elasticache_parameter_group.this[0].name : var.parameter_group_name

  # Segurança
  at_rest_encryption_enabled = var.at_rest_encryption_enabled
  transit_encryption_enabled = var.transit_encryption_enabled
  auth_token                 = var.transit_encryption_enabled && var.auth_token != "" ? var.auth_token : null

  # Backup
  snapshot_retention_limit = var.snapshot_retention_limit
  snapshot_window          = var.snapshot_window
  final_snapshot_identifier = var.final_snapshot_identifier != "" ? var.final_snapshot_identifier : null

  # Manutenção
  maintenance_window         = var.maintenance_window
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.apply_immediately

  # Notificações
  notification_topic_arn = var.notification_topic_arn != "" ? var.notification_topic_arn : null

  # Restore from snapshot
  snapshot_name = var.snapshot_name != "" ? var.snapshot_name : null

  # Log delivery
  dynamic "log_delivery_configuration" {
    for_each = var.slow_log_destination != "" ? [1] : []
    content {
      destination      = var.slow_log_destination
      destination_type = var.slow_log_destination_type
      log_format       = var.slow_log_format
      log_type         = "slow-log"
    }
  }

  dynamic "log_delivery_configuration" {
    for_each = var.engine_log_destination != "" ? [1] : []
    content {
      destination      = var.engine_log_destination
      destination_type = var.engine_log_destination_type
      log_format       = var.engine_log_format
      log_type         = "engine-log"
    }
  }

  tags = local.common_tags

  lifecycle {
    ignore_changes = [auth_token]
  }
}

###############################################################################
# CloudWatch Alarms
###############################################################################

resource "aws_cloudwatch_metric_alarm" "cpu" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-redis-high-cpu"
  alarm_description   = "CPU alta no ElastiCache Redis ${var.name}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "EngineCPUUtilization"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = var.alarm_cpu_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.this.id
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "memory" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-redis-low-memory"
  alarm_description   = "Memória baixa no ElastiCache Redis ${var.name}"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 2
  metric_name         = "FreeableMemory"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = var.alarm_memory_threshold_bytes
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.this.id
  }

  tags = local.common_tags
}

resource "aws_cloudwatch_metric_alarm" "connections" {
  count = var.create_cloudwatch_alarms ? 1 : 0

  alarm_name          = "${local.name_prefix}-redis-high-connections"
  alarm_description   = "Conexões altas no ElastiCache Redis ${var.name}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CurrConnections"
  namespace           = "AWS/ElastiCache"
  period              = 300
  statistic           = "Average"
  threshold           = var.alarm_connections_threshold
  treat_missing_data  = "notBreaching"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions

  dimensions = {
    ReplicationGroupId = aws_elasticache_replication_group.this.id
  }

  tags = local.common_tags
}

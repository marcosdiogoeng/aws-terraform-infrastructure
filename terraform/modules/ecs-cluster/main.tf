# ECS Cluster

resource "aws_ecs_cluster" "this" {
  name = var.name

  setting {
    name  = "containerInsights"
    value = "disabled"
  }

  tags = var.tags
}

resource "aws_ecs_cluster_capacity_providers" "this" {
  count        = length(var.capacity_providers) > 0 ? 1 : 0
  cluster_name = aws_ecs_cluster.this.name

  capacity_providers = var.capacity_providers

  dynamic "default_capacity_provider_strategy" {
    for_each = [
      for cp in var.default_capacity_provider_strategy : cp
    ]
    content {
      capacity_provider = default_capacity_provider_strategy.value.capacity_provider
      weight            = try(default_capacity_provider_strategy.value.weight, 1)
      base              = try(default_capacity_provider_strategy.value.base, 0)
    }
  }
}


# KMS Key para criptografia de dados em repouso (opcional)

resource "aws_kms_key" "this" {
  count = var.create_kms_key ? 1 : 0

  description             = "KMS key for ECS cluster ${var.name}"
  deletion_window_in_days = var.kms_key_deletion_window
  enable_key_rotation     = true

  tags = var.tags
}

resource "aws_kms_alias" "this" {
  count = var.create_kms_key ? 1 : 0

  name          = "alias/ecs/${var.name}"
  target_key_id = aws_kms_key.this[0].key_id
}


# CloudWatch Log Group para ECS Exec (audit logs)

resource "aws_cloudwatch_log_group" "exec" {
  count = var.create_exec_log_group ? 1 : 0

  name              = "/ecs/exec/${var.name}"
  retention_in_days = var.exec_log_retention_days
  kms_key_id        = var.create_kms_key ? aws_kms_key.this[0].arn : null

  tags = var.tags
}



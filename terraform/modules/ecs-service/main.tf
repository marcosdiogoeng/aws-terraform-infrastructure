# ==============================================================================
# Module: terraform-aws-ecs-service
# Task Definition + IAM + ECS Service + CloudWatch Logs + Autoscaling
# O serviço se registra em um target group de ALB externo (passado por variável)
# ==============================================================================

data "aws_region" "current" {}

# ==============================================================================
# CloudWatch Log Groups
# Criados automaticamente para containers sem log_configuration customizado
# ==============================================================================
resource "aws_cloudwatch_log_group" "container" {
  for_each = {
    for c in var.container_definitions : c.name => c
    if try(c.log_configuration, null) == null
  }

  name              = "/ecs/${var.cluster_name}/${var.name}/${each.key}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.cloudwatch_kms_key_arn

  tags = var.tags
}

# ==============================================================================
# IAM – Task Execution Role
# ==============================================================================
data "aws_iam_policy_document" "ecs_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:SourceArn"
      values   = ["arn:aws:ecs:${data.aws_region.current.name}:*:*"]
    }
  }
}

resource "aws_iam_role" "execution" {
  count              = var.create_execution_role ? 1 : 0
  name               = coalesce(var.execution_role_name, "${var.name}-ecs-execution")
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "execution_managed" {
  count      = var.create_execution_role ? 1 : 0
  role       = aws_iam_role.execution[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role_policy" "execution_secrets" {
  count = var.create_execution_role ? 1 : 0
  name  = "secrets-access"
  role  = aws_iam_role.execution[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["ssm:GetParameters", "secretsmanager:GetSecretValue", "kms:Decrypt"]
      Resource = length(var.secret_arns) > 0 ? var.secret_arns : ["*"]
    }]
  })
}

resource "aws_iam_role_policy" "execution_logs" {
  count = var.create_execution_role ? 1 : 0
  name  = "cloudwatch-logs"
  role  = aws_iam_role.execution[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents",
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams"
      ]
      Resource = ["*"]
    }]
  })
}

locals {
  execution_role_arn = var.create_execution_role ? aws_iam_role.execution[0].arn : var.execution_role_arn
}

# ==============================================================================
# IAM – Task Role
# ==============================================================================
resource "aws_iam_role" "task" {
  count              = var.create_task_role ? 1 : 0
  name               = coalesce(var.task_role_name, "${var.name}-ecs-task")
  assume_role_policy = data.aws_iam_policy_document.ecs_assume.json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "task_custom" {
  for_each   = var.create_task_role ? toset(var.task_role_policy_arns) : toset([])
  role       = aws_iam_role.task[0].name
  policy_arn = each.value
}

resource "aws_iam_role_policy" "task_inline" {
  count = var.create_task_role && var.task_role_inline_policy != null ? 1 : 0
  name  = "inline-policy"
  role  = aws_iam_role.task[0].id
  policy = var.task_role_inline_policy
}

resource "aws_iam_role_policy" "task_exec_command" {
  count = var.create_task_role && var.enable_execute_command ? 1 : 0
  name  = "ecs-exec-command"
  role  = aws_iam_role.task[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = [
        "ssmmessages:CreateControlChannel",
        "ssmmessages:CreateDataChannel",
        "ssmmessages:OpenControlChannel",
        "ssmmessages:OpenDataChannel"
      ]
      Resource = ["*"]
    }]
  })
}

locals {
  task_role_arn = var.create_task_role ? aws_iam_role.task[0].arn : var.task_role_arn
}

# ==============================================================================
# Task Definition
# ==============================================================================
locals {
  container_definitions_json = jsonencode([
    for c in var.container_definitions : merge(
      # Campos obrigatórios
      {
        name      = c.name
        image     = c.image
        essential = try(c.essential, true)
      },
      # Port mappings
      try(length(c.port_mappings), 0) > 0 ? {
        portMappings = [
          for p in c.port_mappings : {
            containerPort = p.container_port
            hostPort      = try(p.host_port, p.container_port)
            protocol      = try(p.protocol, "tcp")
            name          = try(p.name, null)
          }
        ]
      } : {},
      # Environment variables
      try(length(c.environment), 0) > 0 ? {
        environment = [for k, v in c.environment : { name = k, value = v }]
      } : {},
      # Secrets (SSM / Secrets Manager)
      try(length(c.secrets), 0) > 0 ? {
        secrets = [for s in c.secrets : { name = s.name, valueFrom = s.value_from }]
      } : {},
      # Log configuration – usa awslogs por padrão
      {
        logConfiguration = try(c.log_configuration, {
          logDriver = "awslogs"
          options = {
            "awslogs-group"         = "/ecs/${var.cluster_name}/${var.name}/${c.name}"
            "awslogs-region"        = data.aws_region.current.name
            "awslogs-stream-prefix" = "ecs"
          }
        })
      },
      # Recursos
      try(c.cpu, null) != null ? { cpu = c.cpu } : {},
      try(c.memory, null) != null ? { memory = c.memory } : {},
      try(c.memory_reservation, null) != null ? { memoryReservation = c.memory_reservation } : {},
      # Overrides de entrypoint/cmd
      try(c.command, null) != null ? { command = c.command } : {},
      try(c.entry_point, null) != null ? { entryPoint = c.entry_point } : {},
      try(c.working_directory, null) != null ? { workingDirectory = c.working_directory } : {},
      # Filesystem
      { readonlyRootFilesystem = try(c.readonly_root_filesystem, false) },
      # Mount points e volumes
      try(length(c.mount_points), 0) > 0 ? { mountPoints = c.mount_points } : {},
      try(length(c.volumes_from), 0) > 0 ? { volumesFrom = c.volumes_from } : {},
      # Health check nativo ECS
      try(c.health_check, null) != null ? { healthCheck = c.health_check } : {},
      # Dependências entre containers
      try(length(c.depends_on), 0) > 0 ? { dependsOn = c.depends_on } : {},
      # Configurações adicionais
      try(c.linux_parameters, null) != null ? { linuxParameters = c.linux_parameters } : {},
      try(length(c.ulimits), 0) > 0 ? { ulimits = c.ulimits } : {},
      try(c.user, null) != null ? { user = c.user } : {},
      try(c.docker_labels, null) != null ? { dockerLabels = c.docker_labels } : {},
      try(c.stop_timeout, null) != null ? { stopTimeout = c.stop_timeout } : {},
      try(c.start_timeout, null) != null ? { startTimeout = c.start_timeout } : {},
      try(c.system_controls, null) != null ? { systemControls = c.system_controls } : {},
      try(c.extra_hosts, null) != null ? { extraHosts = c.extra_hosts } : {},
      try(c.repository_credentials, null) != null ? { repositoryCredentials = c.repository_credentials } : {}
    )
  ])
}

resource "aws_ecs_task_definition" "this" {
  family                   = coalesce(var.task_family, var.name)
  container_definitions    = local.container_definitions_json
  cpu                      = var.task_cpu
  memory                   = var.task_memory
  network_mode             = var.network_mode
  requires_compatibilities = var.requires_compatibilities
  task_role_arn            = local.task_role_arn
  execution_role_arn       = local.execution_role_arn

  dynamic "volume" {
    for_each = var.volumes
    content {
      name = volume.value.name

      dynamic "efs_volume_configuration" {
        for_each = try(volume.value.efs, null) != null ? [volume.value.efs] : []
        content {
          file_system_id          = efs_volume_configuration.value.file_system_id
          root_directory          = try(efs_volume_configuration.value.root_directory, "/")
          transit_encryption      = try(efs_volume_configuration.value.transit_encryption, "ENABLED")
          transit_encryption_port = try(efs_volume_configuration.value.transit_encryption_port, null)
          dynamic "authorization_config" {
            for_each = try(efs_volume_configuration.value.access_point_id, null) != null ? [1] : []
            content {
              access_point_id = efs_volume_configuration.value.access_point_id
              iam             = try(efs_volume_configuration.value.iam, "DISABLED")
            }
          }
        }
      }

      dynamic "docker_volume_configuration" {
        for_each = try(volume.value.docker, null) != null ? [volume.value.docker] : []
        content {
          scope         = try(docker_volume_configuration.value.scope, "task")
          autoprovision = try(docker_volume_configuration.value.autoprovision, false)
          driver        = try(docker_volume_configuration.value.driver, "local")
          driver_opts   = try(docker_volume_configuration.value.driver_opts, {})
          labels        = try(docker_volume_configuration.value.labels, {})
        }
      }
    }
  }

  runtime_platform {
    operating_system_family = var.operating_system_family
    cpu_architecture        = var.cpu_architecture
  }

  tags = var.tags

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [aws_cloudwatch_log_group.container]
}

# ==============================================================================
# ECS Service
# ==============================================================================
resource "aws_ecs_service" "this" {
  name                               = var.name
  cluster                            = var.cluster_arn
  task_definition                    = aws_ecs_task_definition.this.arn
  desired_count                      = var.desired_count
  launch_type                        = length(var.capacity_provider_strategy) > 0 ? null : var.launch_type
  platform_version                   = var.launch_type == "FARGATE" && length(var.capacity_provider_strategy) == 0 ? var.platform_version : null
  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  enable_execute_command             = var.enable_execute_command
  force_new_deployment               = var.force_new_deployment
  wait_for_steady_state              = var.wait_for_steady_state
  propagate_tags                     = var.propagate_tags
  health_check_grace_period_seconds  = var.target_group_arn != null ? var.health_check_grace_period_seconds : null

  network_configuration {
    subnets          = var.subnets
    security_groups  = var.security_groups
    assign_public_ip = var.assign_public_ip
  }

  # Registra no target group do ALB externo (opcional)
  dynamic "load_balancer" {
    for_each = var.target_group_arn != null ? [1] : []
    content {
      target_group_arn = var.target_group_arn
      container_name   = var.load_balancer_container_name
      container_port   = var.load_balancer_container_port
    }
  }

  dynamic "capacity_provider_strategy" {
    for_each = var.capacity_provider_strategy
    content {
      capacity_provider = capacity_provider_strategy.value.capacity_provider
      weight            = try(capacity_provider_strategy.value.weight, 1)
      base              = try(capacity_provider_strategy.value.base, 0)
    }
  }

  deployment_circuit_breaker {
    enable   = var.deployment_circuit_breaker_enable
    rollback = var.deployment_circuit_breaker_rollback
  }

  deployment_controller {
    type = var.deployment_controller_type
  }

  dynamic "service_connect_configuration" {
    for_each = var.service_connect_configuration != null ? [var.service_connect_configuration] : []
    content {
      enabled   = true
      namespace = try(service_connect_configuration.value.namespace, null)
      dynamic "service" {
        for_each = try(service_connect_configuration.value.services, [])
        content {
          port_name      = service.value.port_name
          discovery_name = try(service.value.discovery_name, null)
          client_alias {
            port     = service.value.port
            dns_name = try(service.value.dns_name, null)
          }
        }
      }
    }
  }

  tags = var.tags

  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }
}

# ==============================================================================
# Application Autoscaling
# ==============================================================================
resource "aws_appautoscaling_target" "this" {
  count = var.autoscaling_enabled ? 1 : 0

  max_capacity       = var.autoscaling_max_capacity
  min_capacity       = var.autoscaling_min_capacity
  resource_id        = "service/${var.cluster_name}/${var.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"

  depends_on = [aws_ecs_service.this]
}

resource "aws_appautoscaling_policy" "cpu" {
  count = var.autoscaling_enabled && var.autoscaling_cpu_target != null ? 1 : 0

  name               = "${var.name}-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this[0].resource_id
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value       = var.autoscaling_cpu_target
    scale_in_cooldown  = var.autoscaling_scale_in_cooldown
    scale_out_cooldown = var.autoscaling_scale_out_cooldown
  }
}

resource "aws_appautoscaling_policy" "memory" {
  count = var.autoscaling_enabled && var.autoscaling_memory_target != null ? 1 : 0

  name               = "${var.name}-memory"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this[0].resource_id
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageMemoryUtilization"
    }
    target_value       = var.autoscaling_memory_target
    scale_in_cooldown  = var.autoscaling_scale_in_cooldown
    scale_out_cooldown = var.autoscaling_scale_out_cooldown
  }
}

resource "aws_appautoscaling_policy" "alb_requests" {
  count = var.autoscaling_enabled && var.autoscaling_alb_requests_target != null ? 1 : 0

  name               = "${var.name}-alb-requests"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.this[0].resource_id
  scalable_dimension = aws_appautoscaling_target.this[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.this[0].service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ALBRequestCountPerTarget"
      resource_label         = "${var.alb_arn_suffix}/${var.target_group_arn_suffix}"
    }
    target_value       = var.autoscaling_alb_requests_target
    scale_in_cooldown  = var.autoscaling_scale_in_cooldown
    scale_out_cooldown = var.autoscaling_scale_out_cooldown
  }
}

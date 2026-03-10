################################################################################
# RDS Subnet Group
################################################################################
resource "aws_db_subnet_group" "this" {
  count = var.create_db_subnet_group ? 1 : 0

  name        = coalesce(var.db_subnet_group_name, var.identifier)
  description = "Subnet group for ${var.identifier}"
  subnet_ids  = var.subnet_ids

  tags = merge(var.tags, { Name = coalesce(var.db_subnet_group_name, var.identifier) })
}

################################################################################
# RDS Security Group
################################################################################
resource "aws_security_group" "this" {
  count = var.create_security_group ? 1 : 0

  name        = coalesce(var.security_group_name, "${var.identifier}-sg")
  description = "Security group for RDS ${var.identifier}"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = coalesce(var.security_group_name, "${var.identifier}-sg") })
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = var.create_security_group ? { for idx, cidr in var.allowed_cidr_blocks : idx => cidr } : {}

  security_group_id = aws_security_group.this[0].id
  cidr_ipv4         = each.value
  from_port         = var.port
  to_port           = var.port
  ip_protocol       = "tcp"

  tags = var.tags
}

resource "aws_vpc_security_group_ingress_rule" "sg" {
  for_each = var.create_security_group ? { for idx, sg in var.allowed_security_group_ids : idx => sg } : {}

  security_group_id            = aws_security_group.this[0].id
  referenced_security_group_id = each.value
  from_port                    = var.port
  to_port                      = var.port
  ip_protocol                  = "tcp"

  tags = var.tags
}

resource "aws_vpc_security_group_egress_rule" "this" {
  count = var.create_security_group ? 1 : 0

  security_group_id = aws_security_group.this[0].id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"

  tags = var.tags
}

################################################################################
# RDS Parameter Group
################################################################################
resource "aws_db_parameter_group" "this" {
  count = var.create_db_parameter_group ? 1 : 0

  name        = coalesce(var.parameter_group_name, "${var.identifier}-pg")
  family      = var.parameter_group_family
  description = "Parameter group for ${var.identifier}"

  dynamic "parameter" {
    for_each = var.parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = lookup(parameter.value, "apply_method", "immediate")
    }
  }

  tags = merge(var.tags, { Name = coalesce(var.parameter_group_name, "${var.identifier}-pg") })

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# RDS Option Group
################################################################################
resource "aws_db_option_group" "this" {
  count = var.create_db_option_group ? 1 : 0

  name                     = coalesce(var.option_group_name, "${var.identifier}-og")
  engine_name              = var.engine
  major_engine_version     = var.major_engine_version
  option_group_description = "Option group for ${var.identifier}"

  dynamic "option" {
    for_each = var.options
    content {
      option_name                    = option.value.option_name
      port                           = lookup(option.value, "port", null)
      version                        = lookup(option.value, "version", null)
      db_security_group_memberships  = lookup(option.value, "db_security_group_memberships", null)
      vpc_security_group_memberships = lookup(option.value, "vpc_security_group_memberships", null)

      dynamic "option_settings" {
        for_each = lookup(option.value, "option_settings", [])
        content {
          name  = option_settings.value.name
          value = option_settings.value.value
        }
      }
    }
  }

  tags = merge(var.tags, { Name = coalesce(var.option_group_name, "${var.identifier}-og") })

  lifecycle {
    create_before_destroy = true
  }
}

################################################################################
# Random Password
################################################################################
resource "random_password" "master" {
  count = var.manage_master_user_password && var.password == null && var.snapshot_identifier == null && var.restore_to_point_in_time == null ? 1 : 0

  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

################################################################################
# Secrets Manager - Master Password
################################################################################
resource "aws_secretsmanager_secret" "master_password" {
  count = var.manage_master_user_password && var.password == null && var.snapshot_identifier == null && var.restore_to_point_in_time == null ? 1 : 0

  name                    = "rds/${var.identifier}/master-password"
  description             = "Master password for RDS ${var.identifier}"
  recovery_window_in_days = var.secret_recovery_window_in_days

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "master_password" {
  count = var.manage_master_user_password && var.password == null && var.snapshot_identifier == null && var.restore_to_point_in_time == null ? 1 : 0

  secret_id = aws_secretsmanager_secret.master_password[0].id
  secret_string = jsonencode({
    username = var.username
    password = random_password.master[0].result
    host     = aws_db_instance.this.address
    port     = var.port
    dbname   = var.db_name
  })
}

################################################################################
# RDS Instance
################################################################################
resource "aws_db_instance" "this" {
  identifier = var.identifier

  # Engine
  # Quando snapshot_identifier é informado, engine/engine_version são herdados do snapshot.
  # Ainda podem ser definidos para forçar um upgrade de versão na restauração.
  engine         = var.engine
  engine_version = var.engine_version
  instance_class = var.instance_class

  # Storage
  # allocated_storage e max_allocated_storage são ignorados na restauração por snapshot.
  allocated_storage     = var.snapshot_identifier != null ? null : var.allocated_storage
  max_allocated_storage = var.snapshot_identifier != null ? null : (var.max_allocated_storage > 0 ? var.max_allocated_storage : null)
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted
  kms_key_id            = var.kms_key_id
  iops                  = var.iops
  storage_throughput    = var.storage_throughput

  # Database
  # username, password e db_name são ignorados na restauração por snapshot:
  # o RDS herda esses valores diretamente do snapshot de origem.
  db_name  = var.snapshot_identifier != null ? null : var.db_name
  username = var.snapshot_identifier != null ? null : var.username
  password = var.snapshot_identifier != null ? null : (
    var.manage_master_user_password && var.password == null ? random_password.master[0].result : var.password
  )
  port     = var.port

  # Network
  db_subnet_group_name   = var.create_db_subnet_group ? aws_db_subnet_group.this[0].name : var.db_subnet_group_name
  vpc_security_group_ids = concat(
    var.create_security_group ? [aws_security_group.this[0].id] : [],
    var.additional_security_group_ids
  )
  publicly_accessible    = var.publicly_accessible
  availability_zone      = var.multi_az ? null : var.availability_zone
  multi_az               = var.multi_az

  # Parameter & Option Group
  parameter_group_name = var.create_db_parameter_group ? aws_db_parameter_group.this[0].name : var.parameter_group_name
  option_group_name    = var.create_db_option_group ? aws_db_option_group.this[0].name : var.option_group_name

  # Backup
  backup_retention_period   = var.backup_retention_period
  backup_window             = var.backup_window
  copy_tags_to_snapshot     = var.copy_tags_to_snapshot
  delete_automated_backups  = var.delete_automated_backups
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.identifier}-final-snapshot"

  # Maintenance
  maintenance_window          = var.maintenance_window
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  allow_major_version_upgrade = var.allow_major_version_upgrade
  apply_immediately           = var.apply_immediately

  # Monitoring
  monitoring_interval             = var.monitoring_interval
  monitoring_role_arn             = var.monitoring_interval > 0 ? local.monitoring_role_arn : null
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  performance_insights_enabled    = var.performance_insights_enabled
  performance_insights_kms_key_id = var.performance_insights_enabled ? var.performance_insights_kms_key_id : null
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null

  # Deletion Protection
  deletion_protection = var.deletion_protection

  # Restore from snapshot
  # Restauração por snapshot (cria nova instância a partir de um snapshot existente)
  snapshot_identifier = var.snapshot_identifier

  # Restauração point-in-time (cria nova instância a partir de um ponto no tempo)
  dynamic "restore_to_point_in_time" {
    for_each = var.restore_to_point_in_time != null ? [var.restore_to_point_in_time] : []
    content {
      restore_time                             = restore_to_point_in_time.value.restore_time
      source_db_instance_identifier            = restore_to_point_in_time.value.source_db_instance_identifier
      source_db_instance_automated_backups_arn = restore_to_point_in_time.value.source_db_instance_automated_backups_arn
      source_dbi_resource_id                   = restore_to_point_in_time.value.source_dbi_resource_id
      use_latest_restorable_time               = restore_to_point_in_time.value.use_latest_restorable_time
    }
  }

  # CA Certificate
  ca_cert_identifier = var.ca_cert_identifier

  # License
  license_model = var.license_model

  # Timeouts
  timeouts {
    create = lookup(var.timeouts, "create", "40m")
    update = lookup(var.timeouts, "update", "80m")
    delete = lookup(var.timeouts, "delete", "60m")
  }

  tags = merge(var.tags, { Name = var.identifier })

  lifecycle {
    ignore_changes = [password]
  }

  depends_on = [aws_cloudwatch_log_group.this]
}

################################################################################
# Enhanced Monitoring IAM Role
################################################################################
data "aws_iam_policy_document" "monitoring_assume_role" {
  count = var.create_monitoring_role && var.monitoring_interval > 0 ? 1 : 0

  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "monitoring" {
  count = var.create_monitoring_role && var.monitoring_interval > 0 ? 1 : 0

  name               = "${var.identifier}-monitoring-role"
  assume_role_policy = data.aws_iam_policy_document.monitoring_assume_role[0].json
  tags               = var.tags
}

resource "aws_iam_role_policy_attachment" "monitoring" {
  count = var.create_monitoring_role && var.monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

locals {
  monitoring_role_arn = var.create_monitoring_role ? try(aws_iam_role.monitoring[0].arn, null) : var.monitoring_role_arn
}

################################################################################
# CloudWatch Log Groups
################################################################################
resource "aws_cloudwatch_log_group" "this" {
  for_each = toset(var.enabled_cloudwatch_logs_exports)

  name              = "/aws/rds/instance/${var.identifier}/${each.value}"
  retention_in_days = var.cloudwatch_log_group_retention_in_days
  kms_key_id        = var.cloudwatch_log_group_kms_key_id

  tags = var.tags
}

################################################################################
# Read Replica
################################################################################
resource "aws_db_instance" "read_replica" {
  count = var.replicate_source_db != null ? var.replica_count : 0

  identifier          = "${var.identifier}-replica-${count.index + 1}"
  replicate_source_db = var.replicate_source_db != null ? var.replicate_source_db : aws_db_instance.this.identifier
  instance_class      = coalesce(var.replica_instance_class, var.instance_class)

  # Storage
  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.kms_key_id

  # Network
  vpc_security_group_ids = concat(
    var.create_security_group ? [aws_security_group.this[0].id] : [],
    var.additional_security_group_ids
  )
  publicly_accessible = var.publicly_accessible
  availability_zone   = var.multi_az ? null : var.availability_zone
  multi_az            = var.multi_az
  port                = var.port

  # Monitoring
  monitoring_interval          = var.monitoring_interval
  monitoring_role_arn          = var.monitoring_interval > 0 ? local.monitoring_role_arn : null
  performance_insights_enabled = var.performance_insights_enabled

  # Maintenance
  auto_minor_version_upgrade = var.auto_minor_version_upgrade
  apply_immediately          = var.apply_immediately
  skip_final_snapshot        = true
  deletion_protection        = var.deletion_protection

  tags = merge(var.tags, { Name = "${var.identifier}-replica-${count.index + 1}" })
}
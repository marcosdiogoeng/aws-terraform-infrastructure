################################################################################
# General
################################################################################
variable "identifier" {
  description = "The name of the RDS instance"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

################################################################################
# Engine
################################################################################
variable "engine" {
  description = "The database engine to use (mysql, postgres, mariadb, oracle-se2, sqlserver-ex, etc.). Pode ser omitido quando snapshot_identifier for definido, pois o engine é herdado do snapshot"
  type        = string
  default     = null
}

variable "engine_version" {
  description = "The engine version to use. Pode ser omitido quando snapshot_identifier for definido, pois a versão é herdada do snapshot"
  type        = string
  default     = null
}

variable "instance_class" {
  description = "The instance type of the RDS instance (e.g. db.t3.micro)"
  type        = string
}

variable "major_engine_version" {
  description = "Specifies the major version of the engine that this option group should be associated with (used for option groups)"
  type        = string
  default     = null
}

variable "license_model" {
  description = "License model for the RDS instance (only applicable for Oracle and SQL Server)"
  type        = string
  default     = null
}

################################################################################
# Storage
################################################################################
variable "allocated_storage" {
  description = "The allocated storage in gigabytes"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "When configured, the upper limit to which Amazon RDS can automatically scale the storage (autoscaling). Set to 0 to disable"
  type        = number
  default     = 0
}

variable "storage_type" {
  description = "One of 'standard', 'gp2', 'gp3' or 'io1'"
  type        = string
  default     = "gp3"
}

variable "storage_encrypted" {
  description = "Specifies whether the DB instance is encrypted"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "The ARN for the KMS encryption key. If creating an encrypted replica, set this to the destination KMS ARN"
  type        = string
  default     = null
}

variable "iops" {
  description = "The amount of provisioned IOPS. Setting this implies a storage_type of 'io1' or 'gp3'"
  type        = number
  default     = null
}

variable "storage_throughput" {
  description = "Storage throughput value for the DB instance (only valid for gp3 storage)"
  type        = number
  default     = null
}

################################################################################
# Database
################################################################################
variable "db_name" {
  description = "The name of the database to create when the DB instance is created"
  type        = string
  default     = null
}

variable "username" {
  description = "Username for the master DB user"
  type        = string
  default     = "admin"
}

variable "password" {
  description = "Password for the master DB user. If null and manage_master_user_password is true, a random password will be generated"
  type        = string
  default     = null
  sensitive   = true
}

variable "manage_master_user_password" {
  description = "Set to true to generate a random password and store it in AWS Secrets Manager"
  type        = bool
  default     = true
}

variable "secret_recovery_window_in_days" {
  description = "Number of days AWS Secrets Manager waits before deleting the secret"
  type        = number
  default     = 30
}

variable "port" {
  description = "The port on which the DB accepts connections"
  type        = number
  default     = 5432 # Default to PostgreSQL; override for MySQL (3306), etc.
}

################################################################################
# Network
################################################################################
variable "vpc_id" {
  description = "The VPC ID where the RDS instance will be created"
  type        = string
  default     = null
}

variable "subnet_ids" {
  description = "A list of VPC subnet IDs"
  type        = list(string)
  default     = []
}

variable "create_db_subnet_group" {
  description = "Whether to create a DB subnet group"
  type        = bool
  default     = true
}

variable "db_subnet_group_name" {
  description = "Name of DB subnet group. DB instance will be created in the VPC associated with this subnet group"
  type        = string
  default     = null
}

variable "publicly_accessible" {
  description = "Bool to control if instance is publicly accessible"
  type        = bool
  default     = false
}

variable "availability_zone" {
  description = "The AZ for the RDS instance (ignored when multi_az is true)"
  type        = string
  default     = null
}

variable "multi_az" {
  description = "Specifies if the RDS instance is multi-AZ"
  type        = bool
  default     = false
}

################################################################################
# Security Group
################################################################################
variable "create_security_group" {
  description = "Whether to create a new security group for this RDS instance"
  type        = bool
  default     = true
}

variable "security_group_name" {
  description = "Name of the security group to create. Defaults to identifier-sg"
  type        = string
  default     = null
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the RDS instance"
  type        = list(string)
  default     = []
}

variable "allowed_security_group_ids" {
  description = "List of existing security group IDs to allow access to the RDS instance"
  type        = list(string)
  default     = []
}

variable "additional_security_group_ids" {
  description = "List of additional VPC security group IDs to associate with the RDS instance"
  type        = list(string)
  default     = []
}

################################################################################
# Parameter Group
################################################################################
variable "create_db_parameter_group" {
  description = "Whether to create a database parameter group"
  type        = bool
  default     = false
}

variable "parameter_group_name" {
  description = "Name of the DB parameter group to associate or create"
  type        = string
  default     = null
}

variable "parameter_group_family" {
  description = "The family of the DB parameter group (e.g. mysql8.0, postgres14)"
  type        = string
  default     = null
}

variable "parameters" {
  description = "A list of DB parameter maps to apply"
  type = list(object({
    name         = string
    value        = string
    apply_method = optional(string, "immediate")
  }))
  default = []
}

################################################################################
# Option Group
################################################################################
variable "create_db_option_group" {
  description = "Whether to create a database option group"
  type        = bool
  default     = false
}

variable "option_group_name" {
  description = "Name of the DB option group to associate or create"
  type        = string
  default     = null
}

variable "options" {
  description = "A list of options to apply to the option group"
  type        = any
  default     = []
}

################################################################################
# Backup
################################################################################
variable "backup_retention_period" {
  description = "The days to retain backups for. Must be between 0 and 35. 0 disables backups"
  type        = number
  default     = 7
}

variable "backup_window" {
  description = "The daily time range during which automated backups are created (e.g. 03:00-04:00)"
  type        = string
  default     = "03:00-04:00"
}

variable "copy_tags_to_snapshot" {
  description = "On delete, copy all Instance tags to the final snapshot"
  type        = bool
  default     = true
}

variable "delete_automated_backups" {
  description = "Specifies whether to remove automated backups immediately after the DB instance is deleted"
  type        = bool
  default     = true
}

variable "skip_final_snapshot" {
  description = "Determines whether a final DB snapshot is created before the DB instance is deleted"
  type        = bool
  default     = false
}

variable "snapshot_identifier" {
  description = "ARN ou ID do snapshot para restaurar a instância. Quando definido, username/password/db_name/engine/engine_version são herdados do snapshot e não devem ser informados"
  type        = string
  default     = null
}

variable "restore_to_point_in_time" {
  description = "Configuração para restauração point-in-time. Requer restore_time ou use_latest_restorable_time=true"
  type = object({
    restore_time                             = optional(string, null)  # ex: "2024-01-15T03:00:00Z"
    source_db_instance_identifier            = optional(string, null)
    source_db_instance_automated_backups_arn = optional(string, null)
    source_dbi_resource_id                   = optional(string, null)
    use_latest_restorable_time               = optional(bool, false)
  })
  default = null
}

################################################################################
# Maintenance
################################################################################
variable "maintenance_window" {
  description = "The window to perform maintenance in (e.g. Mon:00:00-Mon:03:00)"
  type        = string
  default     = "Mon:00:00-Mon:03:00"
}

variable "auto_minor_version_upgrade" {
  description = "Indicates that minor engine upgrades will be applied automatically to the DB instance during the maintenance window"
  type        = bool
  default     = true
}

variable "allow_major_version_upgrade" {
  description = "Indicates that major version upgrades are allowed"
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Specifies whether any database modifications are applied immediately, or during the next maintenance window"
  type        = bool
  default     = false
}

variable "ca_cert_identifier" {
  description = "Specifies the identifier of the CA certificate for the DB instance"
  type        = string
  default     = null
}

################################################################################
# Monitoring
################################################################################
variable "monitoring_interval" {
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected (0, 1, 5, 10, 15, 30, 60)"
  type        = number
  default     = 0
}

variable "monitoring_role_arn" {
  description = "The ARN for the IAM role that permits RDS to send enhanced monitoring metrics to CloudWatch Logs. Required if monitoring_interval > 0 and create_monitoring_role is false"
  type        = string
  default     = null
}

variable "create_monitoring_role" {
  description = "Create IAM role with a defined name that permits RDS to send enhanced monitoring metrics to CloudWatch Logs"
  type        = bool
  default     = true
}

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to enable for exporting to CloudWatch logs (audit, error, general, slowquery, postgresql, upgrade)"
  type        = list(string)
  default     = []
}

variable "cloudwatch_log_group_retention_in_days" {
  description = "The number of days to retain CloudWatch logs for the DB instance"
  type        = number
  default     = 7
}

variable "cloudwatch_log_group_kms_key_id" {
  description = "The ARN of the KMS Key to use when encrypting log data"
  type        = string
  default     = null
}

variable "performance_insights_enabled" {
  description = "Specifies whether Performance Insights are enabled"
  type        = bool
  default     = false
}

variable "performance_insights_kms_key_id" {
  description = "The ARN for the KMS key to encrypt Performance Insights data"
  type        = string
  default     = null
}

variable "performance_insights_retention_period" {
  description = "The amount of time in days to retain Performance Insights data (7 or 731)"
  type        = number
  default     = 7
}

################################################################################
# Deletion Protection
################################################################################
variable "deletion_protection" {
  description = "The database can't be deleted when this value is set to true"
  type        = bool
  default     = true
}

################################################################################
# Read Replicas
################################################################################
variable "replica_count" {
  description = "Number of read replicas to create"
  type        = number
  default     = 0
}

variable "replica_instance_class" {
  description = "Instance class for read replicas. Defaults to the primary instance class"
  type        = string
  default     = null
}

variable "replicate_source_db" {
  description = "Specifies that this resource is a Replicate database, and to use this value as the source database"
  type        = string
  default     = null
}

################################################################################
# Timeouts
################################################################################
variable "timeouts" {
  description = "Updated Terraform resource management timeouts"
  type        = map(string)
  default = {
    create = "40m"
    update = "80m"
    delete = "60m"
  }
}
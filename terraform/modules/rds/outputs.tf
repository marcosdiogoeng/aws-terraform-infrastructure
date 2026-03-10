################################################################################
# RDS Instance
################################################################################
output "db_instance_id" {
  description = "The RDS instance ID"
  value       = aws_db_instance.this.id
}

output "db_instance_arn" {
  description = "The ARN of the RDS instance"
  value       = aws_db_instance.this.arn
}

output "db_instance_address" {
  description = "The address of the RDS instance"
  value       = aws_db_instance.this.address
}

output "db_instance_endpoint" {
  description = "The connection endpoint in address:port format"
  value       = aws_db_instance.this.endpoint
}

output "db_instance_hosted_zone_id" {
  description = "The canonical hosted zone ID of the DB instance (to be used in a Route 53 Alias record)"
  value       = aws_db_instance.this.hosted_zone_id
}

output "db_instance_name" {
  description = "The database name"
  value       = aws_db_instance.this.db_name
}

output "db_instance_username" {
  description = "The master username for the database"
  value       = aws_db_instance.this.username
  sensitive   = true
}

output "db_instance_port" {
  description = "The database port"
  value       = aws_db_instance.this.port
}

output "db_instance_status" {
  description = "The RDS instance status"
  value       = aws_db_instance.this.status
}

output "db_instance_engine" {
  description = "The database engine"
  value       = aws_db_instance.this.engine
}

output "db_instance_engine_version_actual" {
  description = "The running version of the database"
  value       = aws_db_instance.this.engine_version_actual
}

output "db_instance_resource_id" {
  description = "The RDS Resource ID of this instance"
  value       = aws_db_instance.this.resource_id
}

################################################################################
# Security Group
################################################################################
output "db_security_group_id" {
  description = "The security group ID of the RDS instance"
  value       = try(aws_security_group.this[0].id, null)
}

output "db_security_group_arn" {
  description = "The ARN of the security group"
  value       = try(aws_security_group.this[0].arn, null)
}

################################################################################
# DB Subnet Group
################################################################################
output "db_subnet_group_id" {
  description = "The db subnet group name"
  value       = try(aws_db_subnet_group.this[0].id, null)
}

output "db_subnet_group_arn" {
  description = "The ARN of the db subnet group"
  value       = try(aws_db_subnet_group.this[0].arn, null)
}

################################################################################
# Parameter Group
################################################################################
output "db_parameter_group_id" {
  description = "The db parameter group id"
  value       = try(aws_db_parameter_group.this[0].id, null)
}

output "db_parameter_group_arn" {
  description = "The ARN of the db parameter group"
  value       = try(aws_db_parameter_group.this[0].arn, null)
}

################################################################################
# Option Group
################################################################################
output "db_option_group_id" {
  description = "The db option group id"
  value       = try(aws_db_option_group.this[0].id, null)
}

output "db_option_group_arn" {
  description = "The ARN of the db option group"
  value       = try(aws_db_option_group.this[0].arn, null)
}

################################################################################
# Monitoring IAM Role
################################################################################
output "enhanced_monitoring_iam_role_name" {
  description = "The name of the monitoring role"
  value       = try(aws_iam_role.monitoring[0].name, null)
}

output "enhanced_monitoring_iam_role_arn" {
  description = "The Amazon Resource Name (ARN) specifying the monitoring role"
  value       = try(aws_iam_role.monitoring[0].arn, null)
}

################################################################################
# Secrets Manager
################################################################################
output "db_master_password_secret_arn" {
  description = "The ARN of the Secrets Manager secret containing the master password"
  value       = try(aws_secretsmanager_secret.master_password[0].arn, null)
}

################################################################################
# Read Replicas
################################################################################
output "db_replica_endpoints" {
  description = "List of read replica endpoints"
  value       = [for r in aws_db_instance.read_replica : r.endpoint]
}

output "db_replica_ids" {
  description = "List of read replica IDs"
  value       = [for r in aws_db_instance.read_replica : r.id]
}

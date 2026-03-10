# Outputs for IAM Module

# User outputs
output "user_name" {
  description = "Nome do usuário IAM criado"
  value       = var.create_user ? aws_iam_user.this[0].name : null
}

output "user_arn" {
  description = "ARN do usuário IAM criado"
  value       = var.create_user ? aws_iam_user.this[0].arn : null
}

output "user_unique_id" {
  description = "ID único do usuário IAM"
  value       = var.create_user ? aws_iam_user.this[0].unique_id : null
}

# Policy outputs
output "policy_name" {
  description = "Nome da policy IAM criada"
  value       = var.create_custom_policy ? (var.policy_json_file != "" ? aws_iam_policy.custom[0].name : aws_iam_policy.inline[0].name) : null
}

output "policy_arn" {
  description = "ARN da policy IAM criada"
  value       = var.create_custom_policy ? (var.policy_json_file != "" ? aws_iam_policy.custom[0].arn : aws_iam_policy.inline[0].arn) : null
}

output "policy_id" {
  description = "ID da policy IAM criada"
  value       = var.create_custom_policy ? (var.policy_json_file != "" ? aws_iam_policy.custom[0].id : aws_iam_policy.inline[0].id) : null
}

# Role outputs
output "role_name" {
  description = "Nome da role IAM criada"
  value       = var.create_role ? aws_iam_role.this[0].name : null
}

output "role_arn" {
  description = "ARN da role IAM criada"
  value       = var.create_role ? aws_iam_role.this[0].arn : null
}

output "role_unique_id" {
  description = "ID único da role IAM"
  value       = var.create_role ? aws_iam_role.this[0].unique_id : null
}

# Access Key outputs
output "access_key_id" {
  description = "Access Key ID do usuário"
  value       = var.create_user && var.create_access_key ? aws_iam_access_key.this[0].id : null
  sensitive   = true
}

output "secret_access_key" {
  description = "Secret Access Key do usuário"
  value       = var.create_user && var.create_access_key ? aws_iam_access_key.this[0].secret : null
  sensitive   = true
}

output "access_key_status" {
  description = "Status da Access Key"
  value       = var.create_user && var.create_access_key ? aws_iam_access_key.this[0].status : null
}

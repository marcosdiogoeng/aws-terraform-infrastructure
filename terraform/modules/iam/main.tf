# Módulo IAM Genérico
# Cria usuários, políticas, roles e access keys

# IAM User
resource "aws_iam_user" "this" {
  count = var.create_user ? 1 : 0
  
  name = var.user_name
  path = var.user_path
  
  tags = merge(
    var.tags,
    {
      Name = var.user_name
    }
  )
}

# IAM Policy - Custom (via JSON file)
resource "aws_iam_policy" "custom" {
  count = var.create_custom_policy && var.policy_json_file != "" ? 1 : 0
  
  name        = var.policy_name
  path        = var.policy_path
  description = var.policy_description
  
  policy = file(var.policy_json_file)
  
  tags = merge(
    var.tags,
    {
      Name = var.policy_name
    }
  )
}

# IAM Policy - Inline (via JSON string)
resource "aws_iam_policy" "inline" {
  count = var.create_custom_policy && var.policy_json_content != "" ? 1 : 0
  
  name        = var.policy_name
  path        = var.policy_path
  description = var.policy_description
  
  policy = var.policy_json_content
  
  tags = merge(
    var.tags,
    {
      Name = var.policy_name
    }
  )
}

# Attach custom policy to user
resource "aws_iam_user_policy_attachment" "custom_policy" {
  count = var.create_user && var.attach_custom_policy_to_user ? 1 : 0
  
  user       = aws_iam_user.this[0].name
  policy_arn = var.policy_json_file != "" ? aws_iam_policy.custom[0].arn : aws_iam_policy.inline[0].arn
  
  depends_on = [
    aws_iam_user.this,
    aws_iam_policy.custom,
    aws_iam_policy.inline
  ]
}

# Attach AWS managed policies to user
resource "aws_iam_user_policy_attachment" "managed_policies" {
  for_each = var.create_user ? toset(var.managed_policy_arns) : toset([])
  
  user       = aws_iam_user.this[0].name
  policy_arn = each.value
}

# IAM Role
resource "aws_iam_role" "this" {
  count = var.create_role ? 1 : 0
  
  name               = var.role_name
  path               = var.role_path
  description        = var.role_description
  assume_role_policy = var.assume_role_policy_json != "" ? var.assume_role_policy_json : file(var.assume_role_policy_file)
  
  max_session_duration = var.role_max_session_duration
  
  tags = merge(
    var.tags,
    {
      Name = var.role_name
    }
  )
}

# Attach custom policy to role
resource "aws_iam_role_policy_attachment" "custom_policy" {
  count = var.create_role && var.attach_custom_policy_to_role ? 1 : 0
  
  role       = aws_iam_role.this[0].name
  policy_arn = var.policy_json_file != "" ? aws_iam_policy.custom[0].arn : aws_iam_policy.inline[0].arn
  
  depends_on = [
    aws_iam_role.this,
    aws_iam_policy.custom,
    aws_iam_policy.inline
  ]
}

# Attach AWS managed policies to role
resource "aws_iam_role_policy_attachment" "managed_policies" {
  for_each = var.create_role ? toset(var.role_managed_policy_arns) : toset([])
  
  role       = aws_iam_role.this[0].name
  policy_arn = each.value
}

# IAM Access Key
resource "aws_iam_access_key" "this" {
  count = var.create_user && var.create_access_key ? 1 : 0
  
  user = aws_iam_user.this[0].name
  
  depends_on = [aws_iam_user.this]
}

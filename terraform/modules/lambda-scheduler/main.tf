resource "aws_iam_role" "this" {
  name = "${local.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "cloudwatch" {
  name = "${local.function_name}-logs"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Resource = "arn:aws:logs:*:*:*"
    }]
  })
}

resource "aws_iam_role_policy" "custom" {
  count = length(var.iam_statements) > 0 ? 1 : 0

  name = "${local.function_name}-custom"
  role = aws_iam_role.this.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      for s in var.iam_statements : {
        Effect   = s.effect
        Action   = s.actions
        Resource = s.resources
      }
    ]
  })
}

resource "aws_lambda_function" "this" {
  function_name    = local.function_name
  filename         = local.zip_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  role             = aws_iam_role.this.arn
  handler          = var.handler
  runtime          = var.runtime
  timeout          = var.timeout

  dynamic "environment" {
    for_each = length(var.environment_variables) > 0 ? [1] : []
    content {
      variables = var.environment_variables
    }
  }

  tags = var.tags

  depends_on = [aws_cloudwatch_log_group.this]
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${local.function_name}"
  retention_in_days = var.log_retention_days
  tags              = var.tags
}

resource "aws_cloudwatch_event_rule" "this" {
  for_each = { for s in var.schedules : s.name => s }

  name                = "${local.function_name}-${each.key}"
  description         = each.value.description
  schedule_expression = each.value.schedule
  tags                = var.tags
}

resource "aws_cloudwatch_event_target" "this" {
  for_each = { for s in var.schedules : s.name => s }

  rule  = aws_cloudwatch_event_rule.this[each.key].name
  arn   = aws_lambda_function.this.arn
  input = each.value.input
}

resource "aws_lambda_permission" "this" {
  for_each = { for s in var.schedules : s.name => s }

  statement_id  = "AllowEventBridge-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.this.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.this[each.key].arn
}

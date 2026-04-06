output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

output "lambda_role_arn" {
  description = "ARN of the Lambda execution IAM role"
  value       = aws_iam_role.this.arn
}

output "event_rule_arns" {
  description = "Map of EventBridge rule ARNs keyed by schedule name"
  value       = { for k, r in aws_cloudwatch_event_rule.this : k => r.arn }
}

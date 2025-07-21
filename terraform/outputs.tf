output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.upgrade_lambda_runtime.function_name
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.upgrade_lambda_runtime.arn
}

output "cloudwatch_schedule_expression" {
  description = "Cron schedule expression"
  value       = aws_cloudwatch_event_rule.schedule.schedule_expression
}

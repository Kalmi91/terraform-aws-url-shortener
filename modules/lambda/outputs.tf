output "shorten_invoke_arn" {
  description = "Invoke ARN of the shorten function (for API Gateway integration)"
  value       = aws_lambda_function.shorten.invoke_arn
}

output "redirect_invoke_arn" {
  description = "Invoke ARN of the redirect function (for API Gateway integration)"
  value       = aws_lambda_function.redirect.invoke_arn
}

output "shorten_function_name" {
  description = "Name of the shorten Lambda function"
  value       = aws_lambda_function.shorten.function_name
}

output "redirect_function_name" {
  description = "Name of the redirect Lambda function"
  value       = aws_lambda_function.redirect.function_name
}

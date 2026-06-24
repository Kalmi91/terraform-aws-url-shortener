output "api_endpoint" {
  description = "Base invoke URL of the HTTP API ($default stage)"
  value       = aws_apigatewayv2_api.this.api_endpoint
}

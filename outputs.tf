output "api_endpoint" {
  description = "Base URL of the deployed HTTP API"
  value       = module.api_gateway.api_endpoint
}

output "dynamodb_table" {
  description = "Name of the DynamoDB table storing the short links"
  value       = module.dynamodb.table_name
}

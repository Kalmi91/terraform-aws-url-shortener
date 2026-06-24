locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

module "dynamodb" {
  source     = "./modules/dynamodb"
  table_name = "${local.name_prefix}-links"
}

module "lambda" {
  source         = "./modules/lambda"
  name_prefix    = local.name_prefix
  dynamodb_table = module.dynamodb.table_name
  dynamodb_arn   = module.dynamodb.table_arn
}

module "api_gateway" {
  source               = "./modules/api_gateway"
  name_prefix          = local.name_prefix
  shorten_lambda_arn   = module.lambda.shorten_invoke_arn
  redirect_lambda_arn  = module.lambda.redirect_invoke_arn
  shorten_lambda_name  = module.lambda.shorten_function_name
  redirect_lambda_name = module.lambda.redirect_function_name
}

data "archive_file" "shorten" {
  type        = "zip"
  source_dir  = "${path.module}/../../src/shorten"
  output_path = "${path.module}/shorten.zip"
}

data "archive_file" "redirect" {
  type        = "zip"
  source_dir  = "${path.module}/../../src/redirect"
  output_path = "${path.module}/redirect.zip"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "lambda" {
  name               = "${var.name_prefix}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Least-privilege: the functions may only read/write the project's own table.
data "aws_iam_policy_document" "dynamodb_access" {
  statement {
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem"]
    resources = [var.dynamodb_arn]
  }
}

resource "aws_iam_role_policy" "dynamodb_access" {
  name   = "${var.name_prefix}-dynamodb-access"
  role   = aws_iam_role.lambda.id
  policy = data.aws_iam_policy_document.dynamodb_access.json
}

resource "aws_lambda_function" "shorten" {
  function_name    = "${var.name_prefix}-shorten"
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.12"
  handler          = "handler.handler"
  filename         = data.archive_file.shorten.output_path
  source_code_hash = data.archive_file.shorten.output_base64sha256
  timeout          = 10

  environment {
    variables = {
      TABLE_NAME = var.dynamodb_table
    }
  }
}

resource "aws_lambda_function" "redirect" {
  function_name    = "${var.name_prefix}-redirect"
  role             = aws_iam_role.lambda.arn
  runtime          = "python3.12"
  handler          = "handler.handler"
  filename         = data.archive_file.redirect.output_path
  source_code_hash = data.archive_file.redirect.output_base64sha256
  timeout          = 10

  environment {
    variables = {
      TABLE_NAME = var.dynamodb_table
    }
  }
}

resource "aws_cloudwatch_log_group" "shorten" {
  name              = "/aws/lambda/${var.name_prefix}-shorten"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "redirect" {
  name              = "/aws/lambda/${var.name_prefix}-redirect"
  retention_in_days = 14
}

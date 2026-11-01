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

# One role per function so each gets only the DynamoDB action it needs.
resource "aws_iam_role" "shorten" {
  name               = "${var.name_prefix}-shorten-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_role" "redirect" {
  name               = "${var.name_prefix}-redirect-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Least-privilege: shorten may only write, redirect may only read, both
# against the project's own table, plus writing to their own log group.
data "aws_iam_policy_document" "shorten" {
  statement {
    actions   = ["dynamodb:PutItem"]
    resources = [var.dynamodb_arn]
  }

  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.shorten.arn}:*"]
  }
}

data "aws_iam_policy_document" "redirect" {
  statement {
    actions   = ["dynamodb:GetItem"]
    resources = [var.dynamodb_arn]
  }

  statement {
    actions   = ["logs:CreateLogStream", "logs:PutLogEvents"]
    resources = ["${aws_cloudwatch_log_group.redirect.arn}:*"]
  }
}

resource "aws_iam_role_policy" "shorten" {
  name   = "${var.name_prefix}-shorten-access"
  role   = aws_iam_role.shorten.id
  policy = data.aws_iam_policy_document.shorten.json
}

resource "aws_iam_role_policy" "redirect" {
  name   = "${var.name_prefix}-redirect-access"
  role   = aws_iam_role.redirect.id
  policy = data.aws_iam_policy_document.redirect.json
}

resource "aws_lambda_function" "shorten" {
  function_name    = "${var.name_prefix}-shorten"
  role             = aws_iam_role.shorten.arn
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
  role             = aws_iam_role.redirect.arn
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

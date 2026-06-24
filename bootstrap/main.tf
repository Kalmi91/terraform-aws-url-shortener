###############################################################################
# Bootstrap: creates the S3 bucket + DynamoDB table that hold the *remote
# state* for the main project. Run this ONCE, before the main stack.
#
# It uses LOCAL state (chicken-and-egg: you cannot store state remotely in a
# bucket that does not exist yet). After applying, copy the outputs into
# environments/<env>/backend.hcl.
###############################################################################

terraform {
  required_version = ">= 1.5"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region for the state backend"
  type        = string
  default     = "eu-central-1"
}

variable "state_bucket_name" {
  description = "Globally-unique name for the Terraform state S3 bucket"
  type        = string
}

variable "lock_table_name" {
  description = "Name of the DynamoDB table used for state locking"
  type        = string
  default     = "terraform-locks"
}

resource "aws_s3_bucket" "state" {
  bucket = var.state_bucket_name
}

resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket                  = aws_s3_bucket.state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "locks" {
  name         = var.lock_table_name
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }
}

output "state_bucket" {
  description = "Use this as 'bucket' in environments/*/backend.hcl"
  value       = aws_s3_bucket.state.id
}

output "lock_table" {
  description = "Use this as 'dynamodb_table' in environments/*/backend.hcl"
  value       = aws_dynamodb_table.locks.name
}

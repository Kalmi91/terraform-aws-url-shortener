variable "name_prefix" {
  description = "Prefix applied to all resource names in this module"
  type        = string
}

variable "dynamodb_table" {
  description = "Name of the DynamoDB table the functions read and write"
  type        = string
}

variable "dynamodb_arn" {
  description = "ARN of the DynamoDB table, used to scope the IAM policy"
  type        = string
}

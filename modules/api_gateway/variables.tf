variable "name_prefix" {
  description = "Prefix applied to all resource names in this module"
  type        = string
}

variable "shorten_lambda_arn" {
  description = "Invoke ARN of the shorten Lambda function"
  type        = string
}

variable "redirect_lambda_arn" {
  description = "Invoke ARN of the redirect Lambda function"
  type        = string
}

variable "shorten_lambda_name" {
  description = "Name of the shorten Lambda function (for the invoke permission)"
  type        = string
}

variable "redirect_lambda_name" {
  description = "Name of the redirect Lambda function (for the invoke permission)"
  type        = string
}

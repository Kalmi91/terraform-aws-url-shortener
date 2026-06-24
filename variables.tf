variable "aws_region" {
  description = "AWS region to deploy into"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Project name, used as a prefix for resource names and tags"
  type        = string
  default     = "url-shortener"
}

variable "environment" {
  description = "Deployment environment identifier (e.g. dev, prod)"
  type        = string
}

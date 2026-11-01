variable "region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Optional AWS CLI profile name. Leave null in CI."
  type        = string
  default     = null
}

variable "project_name" {
  description = "Project name used for naming and tags."
  type        = string
  default     = "serverless-order-processing"
}

variable "environment" {
  description = "Environment name."
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Extra tags for all resources."
  type        = map(string)
  default     = {}
}

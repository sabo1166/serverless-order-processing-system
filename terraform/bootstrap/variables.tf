variable "region" {
  description = "AWS region for the state bucket."
  type        = string
  default     = "us-east-1"
}

variable "aws_profile" {
  description = "Optional AWS CLI profile name. Leave null to use the default credential chain."
  type        = string
  default     = null
}

variable "project_name" {
  description = "Project name used in tags."
  type        = string
  default     = "serverless-order-processing"
}

variable "state_bucket_name" {
  description = "Globally unique name for the Terraform state bucket (chosen by you)."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.state_bucket_name))
    error_message = "Bucket name must be 3-63 chars: lowercase letters, numbers, dots, hyphens."
  }
}

variable "noncurrent_version_expiration_days" {
  description = "Days to keep old (noncurrent) state versions."
  type        = number
  default     = 90
}

variable "tags" {
  description = "Extra tags for all resources."
  type        = map(string)
  default     = {}
}

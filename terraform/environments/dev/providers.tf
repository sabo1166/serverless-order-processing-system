provider "aws" {
  region  = var.region
  profile = var.aws_profile

  default_tags {
    tags = merge(var.tags, {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "terraform"
    })
  }
}

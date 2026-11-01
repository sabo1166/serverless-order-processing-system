provider "aws" {
  region  = var.region
  profile = var.aws_profile # null = default credential chain (CLI profile or env); no keys in code

  default_tags {
    tags = merge(var.tags, {
      Project   = var.project_name
      ManagedBy = "terraform-bootstrap"
    })
  }
}

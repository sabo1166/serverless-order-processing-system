# Partial S3 backend: bucket and region are supplied at init time
# (backend.hcl locally, -backend-config flags in CI). The bucket is the EXISTING state bucket
# described in README.md; it is not created or managed by this configuration. terraform/bootstrap
# defines a separate, optional hardened bucket and does not manage the existing one. The bucket
# must exist before `terraform init` is run here.
#
# Principal needs (see README.md): s3:ListBucket on the bucket; s3:GetObject/PutObject on the
# state key; s3:GetObject/PutObject/DeleteObject on the "<key>.tflock" lock object.
terraform {
  backend "s3" {
    key          = "dev/terraform.tfstate"
    encrypt      = true
    use_lockfile = true # native S3 locking; no DynamoDB table
  }
}

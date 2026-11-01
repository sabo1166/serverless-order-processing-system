# Bootstrap: optional hardened Terraform state bucket

Defines a NEW S3 bucket intended to hold Terraform state. It has NOT been applied from this repo.

This is separate from the bucket the dev environment currently uses. `terraform/environments/dev` stores its state in an
EXISTING bucket (see `terraform/environments/dev/README.md`), which this configuration neither creates nor manages.
Do not point `state_bucket_name` at that existing bucket: this configuration would try to create it and manage its
settings (and `prevent_destroy` is set).

- If you choose to create a new bucket with it, run it once, locally. State for bootstrap itself is LOCAL
  (`terraform.tfstate`, gitignored). This avoids the chicken-and-egg problem of storing the bucket's state in the bucket.
- The dev environment and the GitHub workflow never create a state bucket and do not assume one exists. The workflow's
  `plan` and `apply` jobs are hard-disabled.
- Usage (only with explicit approval): `terraform init`, `terraform plan -var state_bucket_name=<name>`,
  `terraform apply -var state_bucket_name=<name>`.
- Needs a principal able to manage S3 buckets (suggested: `s3:*` limited to the one bucket ARN, plus
  `s3:CreateBucket`). Credentials come from your AWS CLI profile; never from files in this repo.
- Cost: pennies per month. `prevent_destroy` protects the bucket. `terraform destroy` will not remove
  retained object versions you created elsewhere. Back up the local state file.

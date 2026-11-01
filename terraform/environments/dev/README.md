# Dev environment

## Terraform state backend

State lives in the existing S3 bucket `s3-test-serverless-order-processing-system` (region `us-east-1`),
under the key `dev/terraform.tfstate`, with native S3 state locking (`use_lockfile = true`, see `backend.tf`).
The bucket name and region are supplied at init time (`-backend-config`); they are not hardcoded in
`backend.tf` or in the GitHub workflow.

This is an EXISTING bucket. It is not created or managed by this repo. `terraform/bootstrap` defines a separate,
hardened state bucket that has not been applied from this repo; it does not manage the existing bucket.
The bootstrap hardening (versioning, default encryption, public access block, HTTPS-only policy, lifecycle rule)
is therefore not guaranteed for the existing bucket. Check those settings on it before relying on it for real state.
They have not been verified from this repo.

### Initialize locally

```
# Bash (already contains the bucket name; backend.hcl is gitignored)
cp backend.hcl.example backend.hcl

# PowerShell equivalent
Copy-Item backend.hcl.example backend.hcl

terraform init -backend-config=backend.hcl
```

### Backend permissions (documentation only, not applied by this repo)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    { "Sid": "ListStateBucket", "Effect": "Allow", "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::s3-test-serverless-order-processing-system" },
    { "Sid": "StateObject", "Effect": "Allow", "Action": ["s3:GetObject", "s3:PutObject"],
      "Resource": "arn:aws:s3:::s3-test-serverless-order-processing-system/dev/terraform.tfstate" },
    { "Sid": "LockFile", "Effect": "Allow", "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::s3-test-serverless-order-processing-system/dev/terraform.tfstate.tflock" }
  ]
}
```

Terraform also needs permissions for the resources it manages; those are added per step, scoped
to specific services and resources, never admin or `*`.

## GitHub Actions workflow (`.github/workflows/terraform.yml`)

Triggers: pull requests to `main` and pushes to `main`. Workflow permissions: `contents: read`.
There are exactly four jobs, chained `init -> validate -> plan -> apply`:

| Job | Runs? | AWS access | What it does |
|---|---|---|---|
| `init` | on PRs and pushes to `main` | none | Checks Terraform is exactly 1.16.2, then runs `terraform init -backend=false -lockfile=readonly` in this directory. It fails if the committed lock file does not match the provider constraints. |
| `validate` | on PRs and pushes to `main` | none | `terraform fmt -check -recursive`, then `init -backend=false` and `validate` for `terraform/bootstrap`, this directory, and every module under `terraform/modules`. |
| `plan` | **never (hard-disabled)** | none | Would run `terraform init` against the S3 backend and `terraform plan`. Disabled with `if: ${{ false }}`. |
| `apply` | **never (hard-disabled)** | none | Would run `terraform apply -auto-approve`. Disabled with `if: ${{ false }}`. |

Safety properties of the current workflow:

- `init` and `validate` never talk to AWS: no credentials, no OIDC token, no remote backend.
- `plan` and `apply` are doubly locked: a literal `if: ${{ false }}`, and no AWS credentials step and no `id-token: write`
  permission at all. Even if the `if` were removed, they could not authenticate to AWS.
- There are no static AWS credentials anywhere (no access keys, no repository secrets) and no GitHub Environment gate.
- All actions are pinned to full 40-character commit SHAs.

Enabling `plan` or `apply` later needs a separate, reviewed change that adds the AWS OIDC credentials step
(`aws-actions/configure-aws-credentials` with a role ARN built from a repository variable), `id-token: write`, and
least-privilege IAM. Before that:

- AWS access for this workflow must use least-privilege permissions, reviewed and approved, before any cloud operation is
  enabled. Do not enable `plan` or `apply` while the identity they would use has broad or administrator-level permissions.
- When `apply` is enabled it will RE-PLAN and run `terraform apply -auto-approve`, so it can apply different changes than the
  plan job showed, with no human approval step. Add an approval gate (for example a protected GitHub Environment) first.

## GitHub repository variables (not created yet)

No GitHub secrets are needed. Repository variables (Settings -> Secrets and variables -> Actions -> Variables):

| Variable | Value | Used by |
|---|---|---|
| `TF_STATE_BUCKET` | `s3-test-serverless-order-processing-system` | the disabled `plan` and `apply` jobs |
| `AWS_REGION` | `us-east-1` | exported as `TF_VAR_region`; also used by the disabled jobs |

A future OIDC change will also need the AWS account ID (kept as a repository variable, never committed). The current
workflow does not read it. These variables have not been created in GitHub, and the enabled jobs work without them.

## Provider lock files

Every Terraform configuration has its own `.terraform.lock.hcl` (bootstrap, this environment, and each module), pinning
`hashicorp/aws` 6.71.0 (constraint `~> 6.0`) with checksums for both `linux_amd64` (GitHub runners) and `windows_amd64`
(local development). To refresh them after a provider change, run in each directory:

```
terraform providers lock -platform=linux_amd64 -platform=windows_amd64
```

Keep all nine at the same provider version. In CI the `init` job checks only this directory's lock file with
`-lockfile=readonly`; the other eight are used by the `validate` job, which does not run in read-only mode.

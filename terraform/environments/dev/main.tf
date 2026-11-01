locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# Modules are wired in step by step in later steps:
# module "dynamodb"   { source = "../../modules/dynamodb" }
# module "iam"        { source = "../../modules/iam" }
# module "lambdas"    { source = "../../modules/lambdas" }
# module "sqs"        { source = "../../modules/sqs" }
# module "workflow"   { source = "../../modules/workflow" }
# module "api"        { source = "../../modules/api" }
# module "monitoring" { source = "../../modules/monitoring" }

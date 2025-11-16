locals {
  environment_vars = read_terragrunt_config(find_in_parent_folders("env.hcl"))
  region_vars      = read_terragrunt_config(find_in_parent_folders("region.hcl"))
  project_vars     = read_terragrunt_config(find_in_parent_folders("project.hcl"))
  service_vars     = read_terragrunt_config(find_in_parent_folders("service.hcl"))

  aws_region  = local.region_vars.locals.aws_region
  environment = local.environment_vars.locals.environment
  project     = local.project_vars.locals.project_name
  service     = local.service_vars.locals.service_name

  tags = merge(
    { environment = local.environment_vars.locals.environment },
    { region = local.aws_region },
    { project = local.project },
    length(local.service) > 0 ? { service = local.service } : {}
  )

  name = format("%s%s%s", (length(local.project) > 0 ? "${local.project}" : ""), (length(local.service) > 0 ? "-${local.service}" : ""), (length(local.environment) > 0 ? "-${local.environment}" : ""))

}

generate "global_providers" {
  path      = "global_provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region  = "${local.aws_region}"
}
EOF
}


# Configure Terragrunt to automatically store tfstate files in an S3 bucket
remote_state {
  backend = "local"
  config  = null
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

# set global terraform version for all terraform scripts
terragrunt_version_constraint = ">= 0.31.3"
terraform_version_constraint  = ">= 1.0.0"

# ---------------------------------------------------------------------------------------------------------------------
# GLOBAL PARAMETERS
# These variables apply to all configurations in this subfolder. These are automatically merged into the child
# `terragrunt.hcl` config via the include block.
# ---------------------------------------------------------------------------------------------------------------------
inputs = merge(
  local.environment_vars,
  zipmap(["tags"], [local.tags])
)

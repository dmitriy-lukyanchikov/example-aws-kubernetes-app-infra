terraform {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git//?ref=v6.4.0"
}

include {
  path   = find_in_parent_folders()
  expose = true
}

locals {
  vpc_networks = read_terragrunt_config(find_in_parent_folders("vpc_networks.hcl"))
}

dependency "az_list" {
  config_path                             = "../az-list"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "providers", "terragrunt-info"]
  mock_outputs = {
    aws_availability_zones = ["${include.locals.aws_region}a"]
  }
}

inputs = {
  name             = include.locals.name
  cidr             = local.vpc_networks.locals.cidr
  azs              = dependency.az_list.outputs.aws_availability_zones
  database_subnets = local.vpc_networks.locals.database_subnets
  private_subnets  = local.vpc_networks.locals.private_subnets
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"                                                       = "1"
    "kubernetes.io/cluster/cluster-${include.locals.project}-${include.locals.environment}" = "shared"
    "service"                                                                               = "eks"
  }
  public_subnets = local.vpc_networks.locals.public_subnets
  public_subnet_tags = {
    "kubernetes.io/role/elb"                                                                = "1"
    "kubernetes.io/cluster/cluster-${include.locals.project}-${include.locals.environment}" = "shared"
    "service"                                                                               = "eks"
  }
  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  enable_dns_hostnames = true

  manage_default_route_table     = true
  manage_default_security_group  = true
  default_security_group_ingress = []
  default_security_group_egress  = []

  create_database_subnet_group       = true
  create_database_subnet_route_table = true
  database_subnet_group_tags         = { "service" = "db" }
  database_route_table_tags          = { "service" = "db" }
  database_subnet_tags               = { "service" = "db" }
  database_acl_tags                  = { "service" = "db" }
}



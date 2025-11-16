terraform {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-vpc.git//modules/vpc-endpoints?ref=v5.1.1"
}


include {
  path   = find_in_parent_folders()
  expose = true
}

dependency "vpc" {
  config_path = "../vpc"
  mock_outputs = {
    vpc_id                  = "mocked-vpc-id"
    default_route_table_id  = "mocked-default_route_table_id"
    private_route_table_ids = ["mocked-private_route_table_ids"]
    public_route_table_ids  = ["mocked-public_route_table_ids"]
    public_subnets          = ["mocked_public_subnet-1", "mocked_public_subnet-2", "mocked_public_subnet-3"]
    private_subnets         = ["mocked_private_subnet-1", "mocked_private_subnet-2", "mocked_private_subnet-3"]
  }
}

inputs = {
  vpc_id = dependency.vpc.outputs.vpc_id
  endpoints = {
    "s3" = {
      service         = "s3"
      service_type    = "Gateway"
      route_table_ids = concat([dependency.vpc.outputs.default_route_table_id], dependency.vpc.outputs.private_route_table_ids, dependency.vpc.outputs.public_route_table_ids)
      tags            = { "Name" = "${include.locals.name}-s3", service = "s3" }

    }
    "dynamodb" = {
      service         = "dynamodb"
      service_type    = "Gateway"
      route_table_ids = concat([dependency.vpc.outputs.default_route_table_id], dependency.vpc.outputs.private_route_table_ids, dependency.vpc.outputs.public_route_table_ids)
      tags            = { "Name" = "${include.locals.name}-dynamodb", service = "dynamodb" }
    }
  }
  name = include.locals.name
}



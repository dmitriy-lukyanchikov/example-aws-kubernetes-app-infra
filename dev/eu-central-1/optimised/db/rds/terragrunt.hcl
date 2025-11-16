terraform {
  source = "git::https://github.com/cloudposse/terraform-aws-rds.git//?ref=1.1.2"
}

include {
  path   = find_in_parent_folders()
  expose = true
}

dependency "vpc" {
  config_path                             = "${get_parent_terragrunt_dir()}/${include.locals.environment}/${include.locals.aws_region}/${include.locals.project}/network/vpc"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "providers", "terragrunt-info"]
  mock_outputs = {
    database_subnets = ["fake-database_subnets-id1", "fake-database_subnets-id2"]
    vpc_id           = "fake-vpc-id"
  }
}

dependency "eks_cluster" {
  config_path                             = "${get_parent_terragrunt_dir()}/${include.locals.environment}/${include.locals.aws_region}/${include.locals.project}/eks-cluster/aws/cluster-all/cluster"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "providers", "terragrunt-info"]
  mock_outputs = {
    worker_security_group_id = "mocked-sg-id"
  }
}

inputs = {
  label_order        = ["name"]
  labels_as_tags     = ["name"]
  name               = include.locals.name
  host_name          = "db"
  ca_cert_identifier = "rds-ca-rsa2048-g1"
  database_name      = "test"
  database_user      = "test"
  database_password  = "test"
  security_group_ids = [
    dependency.eks_cluster.outputs.worker_security_group_id,
  ]
  database_port                = 5432
  multi_az                     = false
  storage_type                 = "gp3"
  allocated_storage            = 500
  max_allocated_storage        = 1000
  storage_encrypted            = true
  engine                       = "postgres"
  engine_version               = "17.5"
  major_engine_version         = "17"
  instance_class               = "db.m8g.xlarge"
  db_parameter_group           = "postgres17"
  option_group_name            = "default:postgres-17"
  publicly_accessible          = false
  subnet_ids                   = dependency.vpc.outputs.database_subnets
  vpc_id                       = dependency.vpc.outputs.vpc_id
  auto_minor_version_upgrade   = false
  allow_major_version_upgrade  = false
  apply_immediately            = false
  maintenance_window           = "Mon:03:00-Mon:04:00"
  skip_final_snapshot          = false
  copy_tags_to_snapshot        = true
  backup_retention_period      = 7
  backup_window                = "22:00-03:00"
  performance_insights_enabled = false
  #  availability_zone            = "${include.locals.aws_region}b"

}


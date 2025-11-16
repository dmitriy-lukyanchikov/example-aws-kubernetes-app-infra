terraform {
  source = "${get_parent_terragrunt_dir()}//modules/aws_ssm_association"
}

include {
  path   = find_in_parent_folders()
  expose = true
}

dependency "iam_role" {
  config_path                             = "../iam-role"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "providers", "terragrunt-info"]
  mock_outputs = {
    iam_role_arn = "mocked-iam-policy-arn"
  }
}

dependency "rds" {
  config_path                             = "../../rds"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "providers", "terragrunt-info"]
  mock_outputs = {
    instance_id = "mocked_instance_id"
  }
}

inputs = {
  aws_ssm_association_map = merge(
    { for weekday in ["MON", "TUE", "WED", "THU", "FRI"] : "stop_rds_instance_${weekday}" => {
      name                = "AWS-StopRdsInstance"
      schedule_expression = "cron(00 18 ? * ${weekday} *)"
      parameters = {
        "InstanceId"           = dependency.rds.outputs.instance_id
        "AutomationAssumeRole" = dependency.iam_role.outputs.iam_role_arn
      }
      targets = [
        { key = "ParameterValues", values = [dependency.rds.outputs.instance_id] }
      ]
    } },
    { for weekday in ["MON", "TUE", "WED", "THU", "FRI"] : "start_rds_instance_${weekday}" => {
      name                = "AWS-StartRdsInstance"
      schedule_expression = "cron(00 6 ? * ${weekday} *)"
      parameters = {
        "InstanceId"           = dependency.rds.outputs.instance_id
        "AutomationAssumeRole" = dependency.iam_role.outputs.iam_role_arn
      }
      targets = [
        { key = "ParameterValues", values = [dependency.rds.outputs.instance_id] }
      ]
      }
  })
}



terraform {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-assumable-role?ref=v5.5.7"
}

include {
  path   = find_in_parent_folders()
  expose = true
}

dependency "iam_policy" {
  config_path                             = "../iam-policy"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "providers", "terragrunt-info"]
  mock_outputs = {
    arn = "arn:aws:iam::123456789012:policy/policy_arn"
  }
}


inputs = {

  role_name               = "stop-start-reboot-rds"
  create_role             = true
  create_instance_profile = false
  role_requires_mfa       = false
  force_detach_policies   = true

  trusted_role_services = ["ssm.amazonaws.com"]

  custom_role_policy_arns = [
    dependency.iam_policy.outputs.arn
  ]
}

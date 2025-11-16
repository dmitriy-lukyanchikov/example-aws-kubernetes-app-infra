terraform {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-assumable-role?ref=v4.3.0"
}

include {
  path   = find_in_parent_folders()
  expose = true
}

inputs = {
  role_name               = "cluster-${include.locals.project}-${include.locals.environment}"
  create_role             = true
  create_instance_profile = false
  role_requires_mfa       = false
  force_detach_policies   = true

  trusted_role_services = [
    "ec2.amazonaws.com"
  ]

  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  ]
}

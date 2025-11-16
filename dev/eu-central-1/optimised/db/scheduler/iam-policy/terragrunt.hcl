terraform {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-iam.git//modules/iam-policy?ref=v5.5.7"
}

include {
  path   = find_in_parent_folders()
  expose = true
}

inputs = {

  name        = "stop-start-reboot-rds"
  path        = "/"
  description = "RDS scheduler"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "rds:Describe*",
                "rds:Start*",
                "rds:Stop*",
                "rds:Reboot*",
                "rds:ModifyDBInstance"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

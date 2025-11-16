terraform {
  source = "git::https://github.com/cloudposse/terraform-aws-kms-key.git//?ref=0.10.0"
}

include {
  path   = find_in_parent_folders()
  expose = true
}

inputs = {
  name                    = "cluster-${include.locals.project}-${include.locals.environment}-secret-encryption"
  description             = "KMS key to encrypt secrets on eks cluster cluster-${include.locals.project}-${include.locals.environment}"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  label_order             = ["name"]

  policy = <<EOF
{
  "Id": "eks-cluster-secrets",
  "Version":"2012-10-17",
  "Statement": [
    {
      "Sid":  "Allow administrators",
      "Effect": "Allow",
      "Principal": {
        "AWS": ["arn:aws:iam::*:root"]
       },
      "Action": [
        "kms:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF
}


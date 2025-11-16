terraform {
  source = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git//?ref=v21.2.0"
}

include {
  path   = find_in_parent_folders()
  expose = true
}

locals {
  eks_managed_node_group_defaults = {
    enable_monitoring              = false
    create_iam_role                = false
    use_latest_ami_release_version = false
    ami_release_version            = "1.32.0-20250123"
    kubernetes_version             = "1.32"
    ami_type                       = "AL2023_x86_64_STANDARD"
    security_group_description     = "EKS managed node group security group"
    security_group_egress_rules = {
      node_egress_internet = {
        description = "Allow node egress access to the Internet."
        ip_protocol = "-1"
        from_port   = "-1"
        to_port     = "-1"
        type        = "egress"
        cidr_ipv4   = "0.0.0.0/0"
      }
    }
    block_device_mappings = {
      xvda = {
        device_name = "/dev/xvda"
        ebs = {
          volume_size           = 50
          volume_type           = "gp3"
          encrypted             = true
          delete_on_termination = true

        }
      }
    }
    force_update_version   = true
    create_launch_template = true
    metadata_options = {
      http_endpoint               = "enabled"
      http_tokens                 = "required"
      http_put_response_hop_limit = 2
      instance_metadata_tags      = "enabled"
    }
    update_config = {
      max_unavailable = 1
    }
    network_interfaces = [
      {
        associate_public_ip_address = false
        delete_on_termination       = true
      }
    ]
  }
}

dependency "vpc" {
  config_path                             = "${get_parent_terragrunt_dir()}/${include.locals.environment}/${include.locals.aws_region}/${include.locals.project}/network/vpc"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "providers", "terragrunt-info"]
  mock_outputs = {
    vpc_cidr_block  = "0.0.0.0/0"
    vpc_id          = "fake_vpc_id"
    public_subnets  = ["mocked_public_subnet-1", "mocked_public_subnet-2", "mocked_public_subnet-3"]
    private_subnets = ["mocked_private_subnet-1", "mocked_private_subnet-2", "mocked_private_subnet-3"]
  }
}

dependency "eks_secret_kms_key" {
  config_path                             = "../../eks_secret_kms_key"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "providers", "terragrunt-info"]
  mock_outputs = {
    key_arn = "fake-key_arn"
  }
}

dependency "node_groups_iam_role" {
  config_path                             = "../iam/node-groups/iam-role"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "providers", "terragrunt-info"]
  mock_outputs = {
    iam_role_arn = "fake-iam_role_arn"
  }
}

inputs = {
  cluster_name                           = "cluster-${include.locals.project}-${include.locals.environment}"
  name                                   = "cluster-${include.locals.project}-${include.locals.environment}"
  prefix_separator                       = ""
  iam_role_name                          = "cluster-${include.locals.project}-${include.locals.environment}"
  security_group_name                    = "cluster-${include.locals.project}-${include.locals.environment}"
  security_group_description             = "EKS cluster security group."
  node_security_group_name               = "cluster-${include.locals.project}-${include.locals.environment}"
  node_security_group_description        = "Security group for all nodes in the cluster."
  kubernetes_version                     = "1.32"
  subnet_ids                             = dependency.vpc.outputs.private_subnets
  vpc_id                                 = dependency.vpc.outputs.vpc_id
  endpoint_private_access                = true
  endpoint_public_access                 = true
  create_cloudwatch_log_group            = true
  cloudwatch_log_group_retention_in_days = 30
  enabled_log_types                      = ["authenticator"]
  enable_irsa                            = true
  authentication_mode                    = "CONFIG_MAP"

  security_group_additional_rules = {
    cluster_egress_internet = {
      description = "Allow cluster egress access to the Internet."
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "egress"
      cidr_blocks = ["0.0.0.0/0"]
    }
    egress_nodes_443 = {
      description                = "Cluster API to node groups"
      protocol                   = "tcp"
      from_port                  = 443
      to_port                    = 443
      type                       = "egress"
      source_node_security_group = true
    }
    egress_nodes_kubelet = {
      description                = "Cluster API to node kubelets"
      protocol                   = "tcp"
      from_port                  = 10250
      to_port                    = 10250
      type                       = "egress"
      source_node_security_group = true
    }
  }

  node_security_group_additional_rules = {
    node_ingress_cluster = {
      description                   = "Allow workers pods to receive communication from the cluster control plane."
      protocol                      = "tcp"
      from_port                     = 1025
      to_port                       = 65535
      type                          = "ingress"
      source_cluster_security_group = true
    }
    node_self = {
      description = "Allow node to communicate with each other."
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = false
    }
  }

  iam_role_additional_policies = {
    ecr = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    eks = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy",
    vpc = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  }

  create_kms_key = false
  encryption_config = {
    provider_key_arn = dependency.eks_secret_kms_key.outputs.key_arn
    resources        = ["secrets"]
  }

  eks_managed_node_groups = {
    default-1 = merge(local.eks_managed_node_group_defaults, {
      capacity_type  = "SPOT"
      desired_size   = 10
      max_size       = 10
      min_size       = 10
      instance_types = ["t3.xlarge", "t3a.xlarge", "m6a.xlarge", "m6i.xlarge", "m5.xlarge", "m5a.xlarge", "m5n.xlarge", "c6a.xlarge", "c6i.xlarge", "c5.xlarge", "c5a.xlarge"]
      subnet_ids     = [dependency.vpc.outputs.private_subnets[0]]
      iam_role_arn   = dependency.node_groups_iam_role.outputs.iam_role_arn
    })

    default-2 = merge(local.eks_managed_node_group_defaults, {
      capacity_type  = "SPOT"
      desired_size   = 10
      max_size       = 10
      min_size       = 10
      instance_types = ["t3.xlarge", "t3a.xlarge", "m6a.xlarge", "m6i.xlarge", "m5.xlarge", "m5a.xlarge", "m5n.xlarge", "c6a.xlarge", "c6i.xlarge", "c5.xlarge", "c5a.xlarge"]
      subnet_ids     = [dependency.vpc.outputs.private_subnets[0]]
      iam_role_arn   = dependency.node_groups_iam_role.outputs.iam_role_arn
    })

    default-3 = merge(local.eks_managed_node_group_defaults, {
      capacity_type  = "SPOT"
      desired_size   = 1
      max_size       = 1
      min_size       = 1
      instance_types = ["m6i.2xlarge", "m6a.2xlarge", "c6a.2xlarge", "c6i.2xlarge", "m5.2xlarge", "m5a.2xlarge", "c5.2xlarge", "c5a.2xlarge", "t3.2xlarge", "t3a.2xlarge"]
      subnet_ids     = [dependency.vpc.outputs.private_subnets[0]]
      iam_role_arn   = dependency.node_groups_iam_role.outputs.iam_role_arn
    })
  }
}


generate "backward_compatible_outputs" {
  path      = "backward_compatible_outputs.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
output "worker_security_group_id" {
  value = try(aws_security_group.node[0].id, "")
}
EOF
}



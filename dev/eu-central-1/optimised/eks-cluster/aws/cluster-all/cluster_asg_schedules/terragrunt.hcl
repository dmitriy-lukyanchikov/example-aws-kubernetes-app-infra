terraform {
  source = "${get_parent_terragrunt_dir()}//modules/aws_autoscaling_schedule"
}

include {
  path   = find_in_parent_folders()
  expose = true
}


dependency "cluster" {
  config_path                             = "../cluster"
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan", "providers", "terragrunt-info"]
  mock_outputs = {
    node_groups = {
      default-1 = {
        scaling_config = [{
          min_size     = 0
          max_size     = 0
          desired_size = 0
        }]
        resources = [{
          autoscaling_groups = [{
            name = "mocked_asg_name"
          }]
        }]
      }
      default-2 = {
        scaling_config = [{
          min_size     = 0
          max_size     = 0
          desired_size = 0
        }]
        resources = [{
          autoscaling_groups = [{
            name = "mocked_asg_name"
          }]
        }]
      }
      default-3 = {
        scaling_config = [{
          min_size     = 0
          max_size     = 0
          desired_size = 0
        }]
        resources = [{
          autoscaling_groups = [{
            name = "mocked_asg_name"
          }]
        }]
      }
    }
  }
}

inputs = {
  autoscaling_schedules_map = {
    "scale-up" = {
      scheduled_action_name = "scale-up"
      autoscaling_group_name_list = [
        dependency.cluster.outputs.node_groups.default-1.resources[0].autoscaling_groups[0].name,
        dependency.cluster.outputs.node_groups.default-2.resources[0].autoscaling_groups[0].name
      ]
      min_size         = 10
      max_size         = 10
      desired_capacity = 10
      recurrence       = "0 6 * * 1-5"
      time_zone        = "UTC"
    }
    "scale-down" = {
      scheduled_action_name = "scale-down"
      autoscaling_group_name_list = [
        dependency.cluster.outputs.node_groups.default-1.resources[0].autoscaling_groups[0].name,
        dependency.cluster.outputs.node_groups.default-2.resources[0].autoscaling_groups[0].name
      ]
      min_size         = 0
      max_size         = 0
      desired_capacity = 0
      time_zone        = "UTC"
      recurrence       = "0 18 * * 1-5"
    }
    "scale-up-2" = {
      scheduled_action_name = "scale-up"
      autoscaling_group_name_list = [
        dependency.cluster.outputs.node_groups.default-3.resources[0].autoscaling_groups[0].name
      ]
      min_size         = 1
      max_size         = 1
      desired_capacity = 1
      recurrence       = "0 6 * * 1-5"
      time_zone        = "UTC"
    }
    "scale-down-2" = {
      scheduled_action_name = "scale-down"
      autoscaling_group_name_list = [
        dependency.cluster.outputs.node_groups.default-3.resources[0].autoscaling_groups[0].name
      ]
      min_size         = 0
      max_size         = 0
      desired_capacity = 0
      time_zone        = "UTC"
      recurrence       = "0 18 * * 1-5"
    }
  }
}


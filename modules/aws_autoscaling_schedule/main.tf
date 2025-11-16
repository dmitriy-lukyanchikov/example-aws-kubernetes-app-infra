locals {
  autoscaling_schedules_list = flatten([
    for schedule_name, v in var.autoscaling_schedules_map : [
      for asg in v.autoscaling_group_name_list : { "${asg}_${schedule_name}" = merge(v, { scheduled_action_name = coalesce(v.scheduled_action_name, schedule_name), autoscaling_group_name = asg }) }
    ]
  ])

  autoscaling_schedules_map = zipmap(
    flatten(
      [for item in local.autoscaling_schedules_list : keys(item)]
    ),
    flatten(
      [for item in local.autoscaling_schedules_list : values(item)]
  ))
}


resource "aws_autoscaling_schedule" "main" {
  for_each = local.autoscaling_schedules_map

  scheduled_action_name  = each.value["scheduled_action_name"]
  autoscaling_group_name = each.value["autoscaling_group_name"]
  min_size               = lookup(each.value, "min_size", null)
  max_size               = lookup(each.value, "max_size", null)
  desired_capacity       = lookup(each.value, "desired_capacity", null)
  start_time             = lookup(each.value, "start_time", null)
  end_time               = lookup(each.value, "end_time", null)
  recurrence             = lookup(each.value, "recurrence", null)
  time_zone              = lookup(each.value, "time_zone", null)
}


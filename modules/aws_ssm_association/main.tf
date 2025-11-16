variable "aws_ssm_association_map" {
  type    = map(any)
  default = {}
}

resource "aws_ssm_association" "this" {
  for_each = var.aws_ssm_association_map

  association_name                 = each.key
  name                             = each.value.name
  apply_only_at_cron_interval      = lookup(each.value, "apply_only_at_cron_interval", true)
  parameters                       = lookup(each.value, "parameters", {})
  schedule_expression              = lookup(each.value, "schedule_expression", null)
  automation_target_parameter_name = lookup(each.value, "automation_target_parameter_name", "InstanceId")

  dynamic "targets" {
    for_each = lookup(each.value, "targets", [])
    content {
      key    = targets.value.key
      values = targets.value.values
    }
  }
}

output "aws_ssm_association" {
  value = aws_ssm_association.this
}

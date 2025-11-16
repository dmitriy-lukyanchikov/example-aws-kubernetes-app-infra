# AWS Autoscaling Schedule Module

Creates many `aws_autoscaling_schedule` resources from a single map input, making it easy to start/stop Auto Scaling Groups (including EKS managed node groups) on schedules for cost control.

## Requirements
- Terraform >= 1.0
- AWS provider >= 2.0

## Inputs
- `autoscaling_schedules_map` (map, default: `{}`) — keys are schedule names; each value describes recurrence/times and the target ASG list.
  - `autoscaling_group_name_list` (list) — one or more ASG names to apply the schedule to.
  - `recurrence`, `start_time`, `end_time`, `time_zone` — standard autoscaling schedule fields.
  - `min_size`, `max_size`, `desired_capacity` — capacity settings applied when the schedule fires.
  - `scheduled_action_name` (optional) — defaults to the schedule key if omitted.

## Outputs
- `aws_autoscaling_schedule` — map of created schedules keyed by derived schedule name.

## How it works
- Flattens the input map so each ASG gets its own schedule object, merging the schedule key and ASG name into a unique identifier.
- Allows defining “work hours” and “off hours” (or any other windows) once and reusing them across many ASGs.

## Notes
- Ideal for dev/test clusters where node groups should scale down or to zero outside working hours.
- Pair with the `availability-zones` module to keep AZ count low while schedules trim capacity.

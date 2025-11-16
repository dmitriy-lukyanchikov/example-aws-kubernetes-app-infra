# AWS SSM Association Module

Creates multiple `aws_ssm_association` resources from a single map input. Useful for automating stop/start of EC2 or RDS instances, patching tasks, or any SSM document execution tied to schedules or targets in development environments.

## Requirements
- Terraform >= 1.0
- AWS provider compatible with `aws_ssm_association`

## Inputs
- `aws_ssm_association_map` (map, default: `{}`) — keys become association names; each value configures the document and targets.
  - `name` — SSM document name (e.g., `AWS-StopEC2Instance`).
  - `parameters` (map) — document parameters.
  - `schedule_expression` (string) — cron/Rate expression for when to run.
  - `apply_only_at_cron_interval` (bool, default: `true`) — defer execution to the schedule.
  - `targets` (list) — target selectors, each with `key` (e.g., `tag:Environment`) and `values`.
  - `automation_target_parameter_name` (string, default: `"InstanceId"`) — target parameter name for automation docs.

## Outputs
- `aws_ssm_association` — map of created associations.

## How it works
- Iterates the map to create one association per entry, passing through schedule, parameters, and targets.
- Supports dynamic `targets` blocks so you can aim documents at tagged resources without hard-coding IDs.

## Notes
- Pair with autoscaling schedules: use SSM associations for RDS/EC2 start-stop while ASG schedules handle EKS nodes.
- Ensure IAM permissions allow SSM to invoke the chosen documents on the targeted resources.

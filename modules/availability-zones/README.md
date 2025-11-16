# Availability Zones Module

Lightweight helper to cap the number of Availability Zones used by downstream modules. It queries available AZs in the target region and slices the list to a configurable maximum so non-production stacks can run cheaper, smaller footprints.

## Requirements
- Terraform >= 1.0
- AWS provider >= 2.0

## Inputs
- `max_az_count` (number, default: `2`) — maximum number of AZ names to return.

## Outputs
- `aws_availability_zones` — list of AZ names limited to `max_az_count`.

## How it works
- Uses `data.aws_availability_zones.available_subnets.names` filtered to `state = "available"`.
- Returns the first `max_az_count` entries, suitable for feeding subnet, node group, or ASG definitions that do not need three-AZ spread in dev/test.

## Notes
- Keep `max_az_count` aligned with your HA expectations; for cost-sensitive environments, `1` or `2` AZs often suffice.


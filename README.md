# Example AWS Kubernetes App Infra

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)
![Terraform](https://img.shields.io/badge/Terraform-1.x-blue)
[![Terragrunt](https://img.shields.io/badge/Terragrunt-0.31%2B-green)](#requirements)

Terragrunt/Terraform scaffold that contrasts two AWS development environments:
- **Optimised** — single-AZ, scheduled, endpoint-driven posture aimed at cost reduction.
- **Baseline** — prod-like, always-on posture that mirrors common multi-AZ habits.

The repo supports the article “Designing Cost-Optimized Development Environments on AWS: Practical Strategies for Minimizing Cloud Spend.”

---

## Requirements
- Terraform **≥ 1.0**
- Terragrunt **≥ 0.31**
- AWS account/credentials with rights to create the referenced services
- Optional: remote state backend if you replace the default local backend

---

## Overview
This scaffold demonstrates how to run a Kubernetes-centric development environment on AWS in two distinct ways: a cost-focused posture and a production-like posture. It keeps everything reproducible with Terragrunt and Terraform, wiring shared metadata (region, environment, tags) while letting you swap between an always-on, multi-AZ baseline and a single-AZ, scheduled alternative. The example is anchored in `eu-central-1` and the `dev` environment, and is meant to be a minimal harness you can extend with your own workloads to measure the trade-offs called out in the accompanying paper.

---

## What gets deployed
- A baseline or optimised **dev environment** in `eu-central-1`, ready to apply as-is and extend with your app modules.
- Core network: VPC/subnets/NAT are wired in Terragrunt (baseline uses multi-AZ patterns; optimised consolidates to one NAT and a single-AZ footprint).
- Compute: an EKS control plane with managed node groups/ASGs attached via the configs; schedules are included to scale them down or off-hours.
- Data: RDS and OpenSearch are provisioned as single-AZ (optimised) or multi-AZ/always-on (baseline), with SSM automation available for stop/start.
- Cost controls: optional Spot for worker nodes, Gateway Endpoints for S3/DynamoDB, and map-driven ASG/SSM schedules to curb idle runtime.

---

## Stacks at a glance
- **Baseline**: multi-AZ mindset, multiple NAT paths, databases stay running, EKS/EC2 capacity always on. Prioritizes uptime and parity with production.
- **Optimised**: single-AZ where possible, one NAT Gateway plus VPC Gateway Endpoints for S3/DynamoDB, schedules to stop EC2/RDS/EKS nodes off-hours, minimal replicas for OpenSearch/RDS, optional Spot for non-critical workloads. Accepts slower restarts and some downtime to target **40–70%** savings.

---

## Cost levers demonstrated
- **Single-AZ placement** to avoid cross-AZ data transfer and replication overhead.
- **Gateway Endpoints (S3/DynamoDB)** to keep common data paths private and free of egress.
- **Consolidated NAT** (one per VPC) to cut fixed hourly cost.
- **Scheduled stop/start** for EC2, RDS, and ASG-backed EKS nodes via SSM Automation + EventBridge.
- **Spot adoption** for interruptible, non-critical dev workloads.

---

## Repository structure
- `terragrunt.hcl` — shared inputs from `env.hcl`, `region.hcl`, `project.hcl`, `service.hcl`; tagging; provider/backend generation; version constraints.
- `dev/` — environment root (`environment = "dev"`, region `eu-central-1/region.hcl`).
  - `dev/eu-central-1/baseline` — prod-like example (`project_name = "baseline"`).
  - `dev/eu-central-1/optimised` — cost-optimised example (`project_name = "optimised"`).
- `modules/availability-zones` — limits AZ count for cheaper non-prod footprints.
- `modules/aws_autoscaling_schedule` — map-driven creation of many `aws_autoscaling_schedule` resources.
- `modules/aws_ssm_association` — map-driven SSM associations (e.g., stop/start automation).

---

## Module docs
- [modules/availability-zones](modules/availability-zones/README.md)
- [modules/aws_autoscaling_schedule](modules/aws_autoscaling_schedule/README.md)
- [modules/aws_ssm_association](modules/aws_ssm_association/README.md)

---

## Deploying baseline or optimised
- Choose one stack: `dev/eu-central-1/baseline` **or** `dev/eu-central-1/optimised` (deploy separately).
- From that folder: `terragrunt run-all plan` → `terragrunt run-all apply`.
- Ensure `service.hcl` (and any extra `project.hcl`) exists with `service_name`/`project_name` locals for naming/tagging.
- Swap to your preferred remote backend if you do not want local state.

---

## How the optimised posture works
- Places EC2/EKS/RDS/OpenSearch in a single AZ where allowed to remove cross-AZ costs.
- Uses one NAT Gateway plus S3/DynamoDB Gateway Endpoints to keep traffic private and inexpensive.
- Schedules Auto Scaling Groups (including EKS managed node groups) to scale down/off outside work hours; relies on SSM Automation with EventBridge for RDS/EC2 stop/start.
- Keeps replicas to a minimum (OpenSearch, RDS) so services can be stopped and avoid replication charges.
- Optionally uses Spot instances for dev tasks that tolerate interruption.

---

## Assumptions from the study
- Region: **eu-central-1** (Frankfurt).
- Runtime: weekdays **06:00–18:00 UTC** (~260 hours/month) vs 730 hours always-on.
- RDS reference: single-AZ **db.m8g.xlarge**, **500 GB gp3**, no replicas/Multi-AZ to allow stop/start.
- OpenSearch: single-AZ, minimal replicas.
- EKS/EC2: mixed node groups (e.g., **c6a.xlarge**, **t3.xlarge**, **m7a.2xlarge**); control plane billed 24/7, workers scheduled off-hours.
- Networking: one NAT Gateway shared across private subnets; Gateway Endpoints for S3/DynamoDB.

---

## Benefits
- Clear comparison harness for cost-aware vs prod-like dev environments.
- Reusable Terragrunt layout for tagging, provider setup, and version governance.
- Plug-in modules to add scheduling and endpoint-driven savings without touching core app code.
- Easy to measure: deploy baseline, deploy optimised, and compare bills with identical regions and instance classes.

---

## Reading the results
- Deploy **baseline** when you need production similarity and availability.
- Deploy **optimised** to validate cost controls and downtime tolerance in dev.
- Use the same workload and region in both to quantify the savings outlined in the accompanying paper.

---

## License

This chart is licensed under the **MIT License**.  
You can view the full license text here:  
[https://opensource.org/licenses/MIT](https://opensource.org/licenses/MIT)

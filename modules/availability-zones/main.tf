variable "max_az_count" {
  type    = number
  default = 2
}

output "aws_availability_zones" {
  value = slice(data.aws_availability_zones.available_subnets.names, 0, var.max_az_count)
}

data "aws_availability_zones" "available_subnets" {
  state = "available"
}

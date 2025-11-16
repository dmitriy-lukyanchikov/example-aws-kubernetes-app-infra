terraform {
  source = "${get_parent_terragrunt_dir()}//modules/availability-zones"
}


include {
  path = find_in_parent_folders()
}

inputs = {
  max_az_count = 3
}

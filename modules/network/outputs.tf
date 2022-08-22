output "instance_subnet_ids" {
  value = local.instance_subnet_ids
}

output "vpc_id" {
  value = data.aws_vpc.selected_vpc.id
}
output "ids" {
  value = aws_instance.this[*].id
}

output "private_ips" {
  value = aws_instance.this[*].private_ip
}

output "sg_id" {
  value = module.security_groups.sg_id
}
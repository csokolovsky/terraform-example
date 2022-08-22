locals {
  default_sg = var.default_sg ? [for d in data.aws_security_group.default: d.id] : []
  common_sg = var.common_sg ? [for d in data.aws_security_group.common: d.id] : []
}

module "instance_subnet_ids" {
  source = "../network"
  Tier = var.Tier
  vpc_name = var.vpc_name
}

module "security_groups" {
  source = "../security_groups"
  vpc_id = module.instance_subnet_ids.vpc_id
  service = var.service
  ingress_rules = var.ingress_rules
  egress_rules = var.egress_rules
  ingress_with_source_security_group_id = var.ingress_with_source_security_group_id
}

data "aws_security_group" "common" {
  count = var.common_sg ? 1 : 0
  vpc_id = module.instance_subnet_ids.vpc_id
  name = "common*"
}

data "aws_security_group" "default" {
  count = var.default_sg ? 1 : 0
  vpc_id = module.instance_subnet_ids.vpc_id
  name = "default"
}

resource "aws_instance" "this" {
  count = var.instance_count
  ami = var.ami
  instance_type = var.instance_type
  key_name = var.key_name
  iam_instance_profile = var.iam_instance_profile_id
  subnet_id = element(module.instance_subnet_ids.instance_subnet_ids, count.index % length(module.instance_subnet_ids.instance_subnet_ids))
  vpc_security_group_ids = concat(local.default_sg, local.common_sg, [module.security_groups.sg_id])
  source_dest_check = var.source_dest_check

  root_block_device {
    delete_on_termination = true
    volume_size = var.volume_size
    volume_type = var.volume_type
  }
  volume_tags = {
    Name = "${var.name}-${count.index + 1}"
  }

  tags = {
    Name = "${var.name}-${count.index + 1}.${var.services_domain_name}"
    Service = var.service
  }
}

resource "aws_eip" "this" {
  count = var.Tier == "Public" ? var.instance_count : 0
  instance = aws_instance.this[count.index].id
  tags = {
    Name = "${var.name}-${count.index + 1}.${var.services_domain_name}"
  }
}
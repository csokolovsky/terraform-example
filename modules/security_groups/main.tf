locals {
  ingress_rules = var.ingress_rules != {} ? var.ingress_rules : {}
  ingress_with_source_security_group_id = var.ingress_with_source_security_group_id != {} ? var.ingress_with_source_security_group_id : {}
}

resource "aws_security_group" "this" {
  name        = "${var.service}-access"
  description = "Terraform Managed"
  vpc_id      = var.vpc_id
  tags = {
    Name = "${var.service}-access"
  }
}

## Security group rules with "cidr_blocks"
resource "aws_security_group_rule" "this_ingress" {
  for_each          = tomap(local.ingress_rules)
  description       = each.key
  from_port         = each.value.port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.this.id
  to_port           = each.value.port
  type              = "ingress"
  cidr_blocks       = each.value.cidr_block
}

## Security group rules with "source_security_group_id", but without "cidr_blocks" and "self"
resource "aws_security_group_rule" "this_ingress_with_source_security_group_id" {
  for_each          = tomap(local.ingress_with_source_security_group_id)
  description       = each.key
  from_port         = each.value.port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.this.id
  to_port           = each.value.port
  type              = "ingress"
  source_security_group_id = each.value.source_security_group_id
}

## Security group egress rules
resource "aws_security_group_rule" "this_egress" {
  for_each          = var.egress_rules
  from_port         = each.value.port
  protocol          = each.value.protocol
  security_group_id = aws_security_group.this.id
  to_port           = each.value.port
  type              = "egress"
  cidr_blocks       = each.value.cidr_block
}



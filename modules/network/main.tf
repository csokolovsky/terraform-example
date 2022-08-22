data "aws_vpc" "selected_vpc" {
  filter {
    name   = "tag:Name"
    values = [
      var.vpc_name
    ]
  }
}

data "aws_subnets" "selected_subnets" {
  tags = {
    Tier = var.Tier
  }
  filter {
    name   = "vpc-id"
    values = [
      data.aws_vpc.selected_vpc.id
    ]
  }
}

locals {
  instance_subnet_ids = tolist(data.aws_subnets.selected_subnets.ids)
}
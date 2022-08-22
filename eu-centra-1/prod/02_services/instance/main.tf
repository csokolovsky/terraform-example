provider "aws" {
  region = "eu-central-1"
}

data "aws_vpc" "selected_vpc" {
  filter {
    name = "tag:Name"
    values = [
      "prod-vpc"
    ]
  }
}

data "aws_subnets" "selected_subnets" {
  tags = {
    Tier = "Private"
  }
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected_vpc.id]
  }
}

data "aws_acm_certificate" "ssl_certificate" {
  domain = "example.com"
  statuses = ["ISSUED"]
}

data "aws_route53_zone" "selected" {
  name         = "example.com"
  private_zone = true
}

module "ec2_instance" {
  source        = "../../../../modules/instance"
  ami           = "ami-065deacbcaac64cf2"
  Tier          = "Private"
  instance_type = "t3.large"
  name          = "instance-aws-fr"
  service       = "instance"
  vpc_name      = "prod-vpc"
  default_sg    = false
  common_sg     = false
  volume_size   = 50
  volume_type   = "gp2"
  key_name      = "key_name"
  iam_instance_profile_id = aws_iam_instance_profile.instance_instance_profile.id
  ingress_rules = {
    ssh : {
      port       = 22
      protocol   = "tcp"
      cidr_block = ["10.3.0.0/16"]
    },
    prometheus_access : {
      port = 9100
      protocol = "tcp"
      cidr_block = ["10.3.101.233/32"]
    }
  }
  ingress_with_source_security_group_id = {
    http_access : {
      port = 80
      protocol = "tcp"
      source_security_group_id = module.aws_elb_sg.sg_id
    },
    https : {
      port = 443
      protocol = "tcp"
      source_security_group_id = module.aws_elb_sg.sg_id
    }
  }
}

module "aws_elb_sg" {
  source = "../../../../modules/security_groups"

  service = "instance_lb_access"
  vpc_id  = data.aws_vpc.selected_vpc.id
  ingress_rules = {
    https: {
      port       = 443
      protocol   = "tcp"
      cidr_block = [
        "10.3.0.0/16",
        "10.1.0.0/16",
        "10.0.0.0/16"
      ]
    },
    http: {
      port = 80
      protocol = "tcp"
      cidr_block = [
        "10.3.0.0/16",
        "10.1.0.0/16",
        "10.0.0.0/16"
      ]
    }
    ssh: {
      port = 22
      protocol = "tcp"
      cidr_block = [
        "10.3.0.0/16",
        "10.1.0.0/16",
        "10.0.0.0/16"
      ]
    }
  }
  egress_rules = {
    egress: {
      port = 0
      protocol = "-1"
      cidr_block = ["0.0.0.0/0"]
    }
  }
}

module "aws_elb" {
  source = "../../../../modules/aws_elb"

  name = "instance-lb"
  health_check    = {
    healthy_threshold   = 10
    interval            = 30
    target              = "TCP:80"
    timeout             = 5
    unhealthy_threshold = 2
  }
  internal        = true
  listener        = [
    {
      instance_port     = 80
      instance_protocol = "http"
      lb_port           = 443
      lb_protocol       = "https"
      ssl_certificate_id = data.aws_acm_certificate.ssl_certificate.id
    },
    {
      instance_port     = 80
      instance_protocol = "http"
      lb_port           = 80
      lb_protocol       = "http"
    },
    {
      instance_port     = 22
      instance_protocol = "tcp"
      lb_port           = 22
      lb_protocol       = "tcp"
    }
  ]

  security_groups = [module.aws_elb_sg.sg_id]
  subnets         = data.aws_subnets.selected_subnets.ids
  cross_zone_load_balancing = true
  idle_timeout = 60
  instances = module.ec2_instance.ids
  tags = {
    Managed = "Terraform"
    Service = "instance"
  }
}

resource "aws_route53_record" "instance_dns_record" {
  name    = "instance"
  type    = "CNAME"
  zone_id = data.aws_route53_zone.selected.id
  ttl = "300"
  records = module.aws_elb.dns
}

resource "aws_route53_record" "instance_registry_dns_record" {
  name    = "instance-registry"
  type    = "CNAME"
  zone_id = data.aws_route53_zone.selected.id
  ttl = "300"
  records = module.aws_elb.dns
}

resource "aws_iam_role" "instance_iam_role" {
  name = "instance_iam_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_instance_profile" "instance_instance_profile" {
  name = "instance_instance_profile"
  role = "instance_iam_role"
}

resource "aws_iam_role_policy" "instance_s3_rw" {
  name = "s3-rw-product-instance-registry"
  role   = aws_iam_role.instance_iam_role.id
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "VisualEditor0",
        "Effect": "Allow",
        "Action": [
          "s3:*"
        ],
        "Resource": [
          "arn:aws:s3:::product-instance-registry/*",
          "arn:aws:s3:::product-instance-registry"
        ]
      }
    ]
  })
}

resource "aws_s3_bucket" "s3_registry" {
  bucket = "product-instance-registry"
  lifecycle {
    prevent_destroy = true
  }
  tags = {
    Name = "product-instance-registry"
  }
}
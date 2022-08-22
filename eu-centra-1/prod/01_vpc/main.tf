variable "region" {
  default     = "eu-central-1"
  description = "AWS region"
}

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

data "terraform_remote_state" "service_vpc" {
  backend = "s3"
  config = {
    bucket = "pepe-tf-state"
    key    = "services_vpc/s3/terraform.tfstate"
    region = "eu-central-1"
  }
}

# If need install eks cluster
locals {
  eks_cluster_name = "prod-eks"
}

module "vpc" {
  source  = "registry.terraform.io/terraform-aws-modules/vpc/aws"
  version = "3.2.0"

  name                 = "prod-vpc"
  cidr                 = "10.0.0.0/16"
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
  public_subnets       = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = {
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"
    "Project"                                     = "Prod"
  }

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = "1"
    "Tier"                                        = "Public"
    "Project"                                     = "Prod"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.eks_cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = "1"
    "Tier"                                        = "Private"
    "Project"                                     = "Prod"
  }
}

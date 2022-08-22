terraform {
  backend "s3" {
    bucket = "bucket-name"
    key    = "prod/aws/services/instance/s3/terraform.tfstate"
    region = "eu-central-1"

    dynamodb_table = "dynamodb-table-state-locks"
    encrypt        = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.20.0"
    }
  }

  required_version = ">= 0.14"
}

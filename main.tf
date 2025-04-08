terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.region
  default_tags {
    tags = var.tags
  }
}

resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

module "sftp_server" {
  source = "./modules/sftp_server"

  region                = var.region
  vendor_name           = var.vendor_name
  sftp_user_name        = var.sftp_user_name
  s3_bucket_name_unique = "${var.s3_bucket_name_prefix}-${random_string.bucket_suffix.result}"
  tags                  = var.tags
}

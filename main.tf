terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.6"
}

provider "aws" {
  profile = "iamadmin-general"
  region  = "us-east-1"
}

resource "aws_organizations_organization" "my_org" {
  # This is the main organization imported from the management account
  # which contains all sub-accounts
}
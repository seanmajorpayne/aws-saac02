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
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
  ]


  lifecycle {
    prevent_destroy = true
  }
}

data "aws_caller_identity" "current" {}

resource "aws_cloudtrail" "cloudtrail_main" {
  name                          = "tf-trail-all-accounts"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs_bucket_main.id
  include_global_service_events = true
  is_multi_region_trail         = true
  is_organization_trail         = true
}

resource "aws_s3_bucket" "cloudtrail_logs_bucket_main" {
  bucket = "cloudtrail-logs-bucket-main"
  force_destroy = true
  acl = "private"

  policy = <<POLICY
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AWSCloudTrailAclCheck",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:GetBucketAcl",
            "Resource": "arn:aws:s3:::cloudtrail-logs-bucket-main"
        },
        {
            "Sid": "AWSCloudTrailWrite",
            "Effect": "Allow",
            "Principal": {
              "Service": "cloudtrail.amazonaws.com"
            },
            "Action": "s3:PutObject",
            "Resource": [
              "arn:aws:s3:::cloudtrail-logs-bucket-main/AWSLogs/${data.aws_caller_identity.current.account_id}/*",
              "arn:aws:s3:::cloudtrail-logs-bucket-main/AWSLogs/${aws_organizations_organization.my_org.id}/*"
            ],
            "Condition": {
                "StringEquals": {
                    "s3:x-amz-acl": "bucket-owner-full-control"
                }
            }
        }
    ]
}
POLICY
}

resource "aws_s3_bucket_public_access_block" "block_s3_public" {
  bucket = aws_s3_bucket.cloudtrail_logs_bucket_main.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}



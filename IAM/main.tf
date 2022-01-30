terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.0"
}

provider "aws" {
  profile = "iamadmin-general"
  region  = "us-east-1"
}

resource "aws_s3_bucket" "catpics" {
  bucket = "catpics-sean-terraform-test"
  acl    = "private"

  tags = {
    Name        = "catpics"
    Environment = "General"
  }
}

resource "aws_s3_bucket" "animalpics" {
  bucket = "animalpics-sean-terraform-test"
  acl    = "private"
}

resource "aws_iam_user" "sally" {
  name = "sally"
}

resource "aws_iam_user_policy_attachment" "iam_user_change_password" {
  user = aws_iam_user.sally.name
  policy_arn = "arn:aws:iam::aws:policy/IAMUserChangePassword"
}

resource "aws_iam_policy" "AllowAllS3ExceptCats" {
  name = "AllowAllS3ExceptCats-Policy"
  description = "Access to all buckets except the cats bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action: ["s3:*"],
        Effect: "Allow",
        Resource: "*"
      },
      {
        Action: ["s3:*"],
        Effect: "Deny",
        Resource: [aws_s3_bucket.catpics.arn, join("", [aws_s3_bucket.catpics.arn, "/*"])]
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "iam_user_allow_all_s3_except_cats" {
  user = aws_iam_user.sally.name
  policy_arn = aws_iam_policy.AllowAllS3ExceptCats.arn
}


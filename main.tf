terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  backend "s3" {
    bucket = "vrush-tfstate-bucket"   #Change this
    key    = "vrush-s3-tf-ci.tfstate" #Change this
    region = "ap-southeast-1"
  }
}

provider "aws" {
  region = "ap-southeast-1"
}


data "aws_caller_identity" "current" {}

locals {
  name_prefix = split("/", data.aws_caller_identity.current.arn)[1]
  account_id  = data.aws_caller_identity.current.account_id
}

resource "aws_s3_bucket" "s3_tf" {
  # checkov:skip=CKV2_AWS_62 Reason: Event notifications not required for this bucket
  # checkov:skip=CKV_AWS_18 Reason: Access logging not required for this bucket
  # checkov:skip=CKV_AWS_144 Reason: Cross-region replication not required for this bucket
  # checkov:skip=CKV_AWS_145 Reason: KMS encryption not required for this bucket
  bucket = "${local.name_prefix}-s3-tf-bkt-${local.account_id}"

  lifecycle_rule {
    id      = "expire-objects"
    enabled = true

    expiration {
      days = 365
    }
  }
}

resource "aws_s3_bucket_versioning" "s3_tf_versioning" {
  bucket = aws_s3_bucket.s3_tf.id

  versioning_configuration {
    status = "Enabled"
  }
}


resource "aws_s3_bucket_public_access_block" "s3_tf_block" {
  bucket                  = aws_s3_bucket.s3_tf.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}


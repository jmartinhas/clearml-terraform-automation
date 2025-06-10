###############################################################
# Terraform Data Sources
#
# This file defines data sources used to retrieve existing AWS
# resources and configuration values:
# - aws_key_pair: Fetches an existing EC2 key pair for SSH access
# - aws_route53_zone: Looks up a Route53 DNS zone by domain name
# - aws_s3_bucket: References the S3 bucket used for tfstate storage
###############################################################

# data objects tha r
data "aws_key_pair" "private_key" {
  count = var.ssh_port22 ? 1 : 0
  key_name = var.key_name
}

data "aws_route53_zone" "zone_name" {
  name = var.domain_name
  private_zone = false
}

data "aws_s3_bucket" "tfstate_bucket" {
  bucket = var.tfstate_bucket
}
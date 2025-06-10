###############################################################
# Terraform Input Variables
#
# This file defines all input variables used to configure the
# ClearML AWS infrastructure deployment. Variables include:
# - AWS region and resource naming
# - VPC, subnet, and networking configuration
# - NAT gateway and endpoint options
# - SSH and key pair settings
# - Domain, subdomain, and S3 bucket for tfstate
# - EC2 instance AMI, type, and user data
# - Feature toggles for SSM, password hashing, etc.
# - Region-to-AMI mapping for ClearML server
###############################################################

variable "aws_region" {
  description = "The AWS region to deploy to."
  type        = string
  default     = "eu-west-1"
}


variable "resource_prefix" {
  description = "Prefix for naming AWS resources."
  type        = string
  default     = "clearml"
}

variable "ssh_port22" {
  description = "Security ingress rule: Enable SSH open port 22."
  type        = bool
  default     = true
}

variable "key_name" {
  description = "The name of the key pair to use for SSH access."
  type = string
  default = "id_rsa"
}

variable "domain_name" {
  description = "The domain name for the ClearML server."
  type = string
}

variable "subdomains" {
  description = "The subdomains for the ClearML server."
  type = map(string)
  default = {
    app   = "app.clearml"
    api   = "api.clearml"
    files = "files.clearml"
  }
}

variable "tfstate_bucket" {
  description = "The bucket to store the Terraform state file."
  type = string
}

variable "instance_type" {
  description = "The instance type to use for the ClearML server."
  type = string
  default = "t3a.large"
}

variable "enable_hash_password" {
  description = "Enable password hashing."
  type        = bool
  default     = true
}

variable "apiserver_conf_s3_key" {
  description = "The S3 key for the apiserver.conf file."
  type        = string
  default     = "terraform/CLEARML/server/config/apiserver.conf"
}

variable "secure_conf_s3_key" {
  description = "The S3 key for the secure.conf file."
  type        = string
  default     = "terraform/CLEARML/server/config/secure.conf"
}

variable "user_creds_file" {
  description = "The user credentials file."
  type        = string
  default     = "user_credentials.yaml.gitignore"
}

# See https://clear.ml/docs/latest/docs/deploying_clearml/clearml_server_aws_ec2_ami
variable "region_map" {
  type = map(string)
  default = {
    "af-south-1"     = "ami-0c02f50931989c82c"
    "ap-east-1"      = "ami-09f1923e5a508d1ff"
    "ap-northeast-1" = "ami-02ca0c43f301f7302"
    "ap-northeast-2" = "ami-08a17fdd961b11a95"
    "ap-northeast-3" = "ami-001c15a40ce2abfd9"
    "ap-south-1"     = "ami-06c84aa5aeb0cee85"
    "ap-south-2"     = "ami-0f73b2cb16f6a4c8d"
    "ap-southeast-1" = "ami-02438427c412541bd"
    "ap-southeast-2" = "ami-0ca5327c5659da2d8"
    "ap-southeast-3" = "ami-02c2510f93e9103c2"
    "ap-southeast-4" = "ami-043cc0463fd0d5f65"
    "ap-southeast-5" = "ami-0a89c5a9c39fd05a7"
    "ap-southeast-7" = "ami-09e12423659d893dd"
    "ca-central-1"   = "ami-0c902f35c96b30c39"
    "ca-west-1"      = "ami-0f5ec5964e548adfd"
    "eu-central-1"   = "ami-0879367e77eb2f09f"
    "eu-central-2"   = "ami-096caaa4aada8a7d8"
    "eu-north-1"     = "ami-0800c04d58a0192c6"
    "eu-south-1"     = "ami-0b95afb1fa7fb718c"
    "eu-south-2"     = "ami-0393bdf1fb5212db5"
    "eu-west-1"      = "ami-0faee29c9e77fd277"
    "eu-west-2"      = "ami-0e1a7b05c74d47a17"
    "eu-west-3"      = "ami-0927e68e0d333890e"
    "il-central-1"   = "ami-0282774a5d6f5bbef"
    "me-central-1"   = "ami-0245376f5c1690b9d"
    "me-south-1"     = "ami-0df5d9605c6bcbd87"
    "mx-central-1"   = "ami-0a39df8700027a475"
    "sa-east-1"      = "ami-07e28e8e282e8fc34"
    "us-east-1"      = "ami-066f2e1182971cd2e"
    "us-east-2"      = "ami-007206d639ecc9430"
    "us-west-1"      = "ami-057d8ca86daa6f675"
    "us-west-2"      = "ami-06d802321b6a20774"
  }
}
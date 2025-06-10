###############################################################
# Terraform Providers Configuration
#
# This file configures the required providers for the deployment:
# - AWS: Used for provisioning all AWS resources. The region is
#   set via the aws_region variable.
# - Null: Used for null_resource and other utility resources.
###############################################################

provider "aws" {
  region = var.aws_region
}
provider "null" {}
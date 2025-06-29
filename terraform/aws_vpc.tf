###############################################################
# AWS VPC Module for ClearML Deployment
#
# Provisions a Virtual Private Cloud (VPC) using the
# terraform-aws-modules/vpc/aws module. This setup includes:
#   - One public and one private subnet in eu-west-1a
#   - NAT Gateway with Elastic IP for outbound internet from private subnet
#   - Tags for Terraform and environment tracking
#
# The Elastic IP for the NAT Gateway is created separately and
# passed to the module to allow for IP reuse and management.
###############################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.21.0"

  name = "ClearML VPC"
  cidr = var.vpc_cidr

  azs             = var.az_zones
  private_subnets = var.private_subnets# <= Use private subnets for the ClearML server
  public_subnets  = var.public_subnets

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false
  reuse_nat_ips          = true                    # <= Skip creation of EIPs for the NAT Gateways
  external_nat_ip_ids    = [aws_eip.nat[0].id]        # <= IPs specified here as input to the module

  tags = {
    Terraform = "true"
    Environment = "dev"
  }
}

resource "aws_eip" "nat" {
  count = 1
}
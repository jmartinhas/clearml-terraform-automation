# ClearML Server on AWS with Terraform

Deploy a production-ready ClearML server on AWS using Terraform. This repository provides infrastructure-as-code templates to automate the setup of networking, compute, security, and configuration for ClearML. 

> **Disclaimer:** This project is experimental and under active development. Use at your own discretion.

## Getting Started

If you are familiar with AWS and Terraform, check out the [Quickstart Guide](./docs/QUICKSTART.MD) to get up and running quickly.

## Project Overview

This repository contains all the Terraform modules and scripts needed to deploy a ClearML server on AWS. The setup includes:
- VPC with public/private subnets
- Security groups for EC2 and load balancer
- Application Load Balancer (ALB) with listeners and target groups
- EC2 instance for ClearML
- IAM roles and policies
- Route53 DNS records
- Automated configuration file generation and S3 integration

## Project Status

This project is a work in progress and may change frequently.

## Contents

- [ClearML Server on AWS with Terraform](#clearml-server-on-aws-with-terraform)
  - [Getting Started](#getting-started)
  - [Project Overview](#project-overview)
  - [Project Status](#project-status)
  - [Contents](#contents)
  - [Architecture](#architecture)
  - [AWS Prerequisites](#aws-prerequisites)
  - [Configuration](#configuration)
  - [Usage](#usage)
  - [Support](#support)
  - [Community](#community)
  - [Acknowledgments](#acknowledgments)
  - [Contributing](#contributing)
  - [License](#license)

## Architecture

The deployment provisions the following AWS resources:
- Isolated VPC with public and private subnets
- Security groups for ClearML and ALB
- Application Load Balancer with HTTPS listeners
- EC2 instance for ClearML
- IAM roles for SSM and S3 access
- Route53 DNS records for subdomains
- ACM certificate for SSL

## AWS Prerequisites

Before deploying, ensure you have:

1. **AWS Account** with permissions to create VPC, EC2, S3, IAM, ACM, and Route53 resources.
2. **SSH Key Pair (optional):** Create/import a key pair in your AWS region. [AWS Docs](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html)
3. **SSL Certificate:** Request a certificate in ACM for your domain. [AWS Docs](https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-request-public.html)
4. **Route53 Hosted Zone:** Set up a hosted zone for your domain. [AWS Docs](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/CreatingHostedZone.html)
5. **S3 Bucket for Terraform State:** Create a bucket for storing Terraform state. [AWS Docs](https://docs.aws.amazon.com/AmazonS3/latest/userguide/create-bucket-overview.html)
6. **(Optional) DynamoDB Table:** For state locking. [AWS Docs](https://docs.aws.amazon.com/amazondynamodb/latest/developerguide/HowItWorks.CoreComponents.html)
7. **SSM Session Manager:** Enable SSM for secure, agentless access to EC2. [AWS Docs](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager.html)

## Configuration

### ClearML Configuration Files

The deployment manages the following ClearML configuration files:
- `apiserver.conf` (generated from user credentials and uploaded to S3)
- `secure.conf` (tokens replaced and uploaded to S3)

Other config files (hosts.conf, logging.conf, services.conf) are not managed by this setup.

For more details, see the [ClearML Server Configuration Docs](https://clear.ml/docs/latest/docs/deploying_clearml/clearml_server_config/).

### Terraform

Follow the [Quickstart Guide](./docs/QUICKSTART.MD) for step-by-step deployment instructions.

For more on Terraform usage, see the [Terraform Documentation](https://www.terraform.io/docs/index.html).


This project follows the [CODE_OF_CONDUCT](./CODE_OF_CONDUCT.md). Report unacceptable behavior to a project [CODEOWNER](./CODEOWNERS).

## Contributing

See [CONTRIBUTING](./CONTRIBUTING.md) for contribution guidelines.

## License

See [LICENSE](./LICENSE) for license details.

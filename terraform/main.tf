###############################################################
# ClearML Server EC2 Instance and IAM Configuration
#
# This Terraform file provisions the following AWS resources:
#
# - EC2 instance for ClearML Server, with user data script
# - IAM role and instance profile for SSM and S3 access
# - IAM policy for S3 Get/Put permissions on the tfstate bucket
# - Security group and subnet selection based on SSH access
#
# The EC2 instance is configured to use SSM for management and
# can be launched in either a public or private subnet depending
# on the ssh_port22 variable. The IAM role is attached with both
# SSM and S3 access policies.
###############################################################

resource "aws_instance" "clearmlserver" {
  ami                       = var.ami_id
  instance_type             = var.instance_type
  key_name                  = var.ssh_port22 ? data.aws_key_pair.private_key[0].key_name : null 
  vpc_security_group_ids    = [aws_security_group.clearml_server_sg.id]
  subnet_id                 = var.ssh_port22 ? module.vpc.public_subnets[0] : module.vpc.private_subnets[0]

  user_data = file("${path.module}/userdata.sh")

  iam_instance_profile   =  aws_iam_instance_profile.ssm.id
  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = {
    Name = "clearml-server-tf"
  }
}

resource "aws_iam_instance_profile" "ssm" {
  name = "${var.resource_prefix}-ssm"
  role = aws_iam_role.ssm.name
}

resource "aws_iam_role" "ssm" {
  name        = "${var.resource_prefix}-clearmlserver"
  description = "The role for the clearmlserver instance"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "s3_policy" {
  name        = "s3_get_put_policy"
  description = "Policy to allow Get and Put access to a specific S3 bucket"
  policy      = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "arn:aws:s3:::${var.tfstate_bucket}/*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.ssm.name
  policy_arn = aws_iam_policy.s3_policy.arn
}

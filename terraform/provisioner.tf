###############################################################
# Terraform Provisioners and SSM Automation
#
# This file automates the following tasks for ClearML deployment:
#
# - Installs required Python packages for provisioning scripts
# - Runs Python scripts to generate and upload ClearML config files to S3
# - Uses AWS SSM Documents and Associations to copy config files from S3 to EC2
# - Restarts Docker Compose services after config updates
#
# The process ensures that configuration changes are automatically
# propagated to the ClearML server instance using SSM automation.
###############################################################

resource "null_resource" "install_pip_packages" {
  provisioner "local-exec" {
    command = "pip install -r ./python_scripts/requirements.txt"
  }
}

resource "null_resource" "run_script" {
  triggers = {
    config_hash = filemd5("${path.module}/${var.user_creds_file}")
  }

  provisioner "local-exec" {
    command = "python3 ${path.root}/python_scripts/apiserver.conf.s3.gen.py ${var.enable_hash_password} ${var.tfstate_bucket} ${var.apiserver_conf_s3_key} '${path.root}/${var.user_creds_file}' ${var.domain_name}"
  }
  depends_on = [ null_resource.install_pip_packages ]
}

resource "null_resource" "trigger_ssm" {
  triggers = {
    config_hash = filemd5("${path.module}/${var.user_creds_file}")
  }

  provisioner "local-exec" {
    command = "aws ssm send-command --document-name CopyFileFromS3 --targets 'Key=instanceids,Values=${aws_instance.clearmlserver.id}' --region ${var.aws_region}"
  }
  depends_on = [ aws_lb.clearml_lb ]
}


resource "aws_ssm_document" "copy_file" {
  name          = "CopyFileFromS3"
  document_type = "Command"

  content = jsonencode({
    schemaVersion = "2.2",
    description   = "Copy file from S3 to EC2",
    mainSteps     = [
      {
        action = "aws:runShellScript",
        name   = "copyFile",
        inputs = {
          runCommand = [
            "aws s3 cp s3://${data.aws_s3_bucket.tfstate_bucket.bucket}/${var.apiserver_conf_s3_key} /opt/clearml/config/",
            "sudo chown root:root /opt/clearml/config/apiserver.conf",
            "sudo docker-compose -f /home/ec2-user/docker-compose.yml restart"
          ]
        }
      }
    ]
  })
  depends_on = [ null_resource.run_script ]
}

resource "aws_ssm_association" "copy_file" {
  name       = aws_ssm_document.copy_file.name
  targets {
    key    = "InstanceIds"
    values = [aws_instance.clearmlserver.id]
  }
}

resource "null_resource" "create_secure_conf_s3" {

  provisioner "local-exec" {
    command = "python3 ${path.root}/python_scripts/secure.conf.s3.gen.py  ${var.tfstate_bucket} ${var.secure_conf_s3_key} ${path.root}/python_scripts/secure.conf.default"
  }
  depends_on = [ null_resource.install_pip_packages ]
}

resource "null_resource" "secure_conf_ssm" {
  provisioner "local-exec" {
    command = "aws ssm send-command --document-name CopySecureConfFileFromS3 --targets 'Key=instanceids,Values=${aws_instance.clearmlserver.id}' --region ${var.aws_region}"
  }
  depends_on = [ aws_lb.clearml_lb ]
}


resource "aws_ssm_document" "copy_secure_conf_file" {
  name          = "CopySecureConfFileFromS3"
  document_type = "Command"

  content = jsonencode({
    schemaVersion = "2.2",
    description   = "Copy secure.conf file from S3 to EC2",
    mainSteps     = [
      {
        action = "aws:runShellScript",
        name   = "copyFile",
        inputs = {
          runCommand = [
            "aws s3 cp s3://${data.aws_s3_bucket.tfstate_bucket.bucket}/${var.secure_conf_s3_key} /opt/clearml/config/",
            "sudo chown root:root /opt/clearml/config/secure.conf",
            "sudo docker-compose -f /home/ec2-user/docker-compose.yml restart"
          ]
        }
      }
    ]
  })
  depends_on = [ null_resource.run_script ]
}

resource "aws_ssm_association" "copy_secure_conf_file" {
  name       = aws_ssm_document.copy_secure_conf_file.name
  targets {
    key    = "InstanceIds"
    values = [aws_instance.clearmlserver.id]
  }
}
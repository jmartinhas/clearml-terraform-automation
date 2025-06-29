# ClearML AWS Deployment: Quickstart

This guide will help you launch a ClearML Server on AWS using Terraform. Please follow the steps below to set up your environment.

---

## 1. Domain & Certificate Setup

- **Register your domain** in AWS Route 53. This will automatically create a hosted zone for DNS management.
- **SSL Certificates:**
  As of v0.4, public certificate creation and registration in AWS Certificate Manager is handled automatically by Terraform.

---

## 2. Prepare the Terraform State S3 Bucket

- **Choose a bucket name and region:**
  For example, `clearml-tfstate-example` in `us-east-1`.
- **Create the bucket:**
  You can use the AWS Console or run the provided script (ensure versioning is enabled):
  ```bash
  create_tfstate_bucket.sh <clearml-tfstate-example> <region>
  ```

---

## 3. Configure Terraform Files

Edit the following files to match your environment:

- **`backend.tf`**
  ```hcl
  bucket = "<clearml-tfstate-example>"
  region = "<region>"
  ```

- **`clearml_config.auto.tfvars`**
  ```hcl
  aws_region     = "<region>"
  tfstate_bucket = "<clearml-tfstate-example>"
  ```
  - **SSH Access (Optional):**
    By default, SSH is disabled and SSM Session Manager is used. To enable SSH (places the instance in a public subnet and opens port 22):
    ```hcl
    ssh_port22 = true
    key_name   = "<your_key_pair_name>"
    ```
  - **Domain Name (Required):**
    ```hcl
    domain_name = "yourdomain.com"
    ```
  - **AMI and Instance Type:**
    Find the latest ClearML Server AMI for your region [here](https://clear.ml/docs/latest/docs/deploying_clearml/clearml_server_aws_ec2_ami/#latest-version):
    ```hcl
    ami_id = "<ami_id>"
    # instance_type = "t3a.large"  # default
    ```
  - **User Credentials File:**
    ```hcl
    user_creds_file = "user_credentials.yaml.gitignore"  # (DEFAULT)
    ```

- **Credentials:**
  Copy your credentials file:
  ```bash
  cp user_credentials.yaml user_credentials.yaml.gitignore
  ```
  > Note: `user_credentials.yaml.gitignore` is in `.gitignore`. Keep your credentials secure.

---

## 4. Configuration File Generation

- `apiserver.conf` is generated from your credentials YAML and uploaded to S3 at
  `<clearml-tfstate-example>/terraform/CLEARML/server/config/apiserver.conf`, then delivered to the ClearML server via SSM.
- `secure.conf` is generated with random tokens and also uploaded to S3 and the server.

---

## 5. Deploy with Terraform

1. Initialize Terraform:
   ```bash
   terraform init
   ```
2. Review the plan:
   ```bash
   terraform plan
   ```
3. Apply the configuration:
   ```bash
   terraform apply
   ```
   > If you see an error about the instance not being ready, simply re-run `terraform apply`.

---

## 6. Managing Users

- **To add or remove users:**
  Edit `user_credentials.yaml.gitignore`, then run:
  ```bash
  terraform plan
  terraform apply
  ```
  This will regenerate and deploy the updated `apiserver.conf`.

---





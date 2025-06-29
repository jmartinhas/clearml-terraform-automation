# Quick Start

1. Register a domain name in "Register Domains" in Route 53, which will create a hosted zone.
2. (Automated) In version 0.4 the creation and registration of the public certificates in AWS Certificate Manager is automated.

### AWS CLI Terraform State Bucket Creation

5. Define an S3 bucket name, e.g., `clearml-tfstate-example`, and a region, e.g., `us-east-1`.
6. Run the following command (OPTIONAL: you can also create the bucket in the console; make sure versioning is enabled):
   ```bash
   create_tfstate_bucket.sh clearml-tfstate-example us-east-1
   ```

### Terraform

Modify the following files:

7. `backend.tf` (REQUIRED):
	- `bucket = "<CHANGE THIS>"` -> `clearml-tfstate-example`
	- `region = "<YOUR REGION>"` -> `us-east-1`
8. `clearml_config.auto.tfvars`:
   ```
	aws_region     = "<aws_region>" -> us-east-1`
	tfstate_bucket = "<your_tfstate_bucket>"` -> clearml-tfstate-example
   ```  
    \# Enable SSH (**OPTIONAL**):
    Enabling SSH puts the ClearML instance in the public subnet and opens up port 22 to the world (0.0.0.0). The default is false.
    You can use the EC2 instance console and select "Connect with Session Manager" or install tooling on your computer.
    
    ```hcl
    ssh_port22              = false  # by default, use SSM Session Manager
    key_name                = "<priv_key_name>"
    ```

    \# Domain (**REQUIRED**):
    ```hcl
    domain_name                  = "example.com"  # **CHANGE THIS**
    ```

    \# ClearML Server Settings:

    AMI ID, for the latest see [ClearML Server AWS Community AMIs]([link](https://clear.ml/docs/latest/docs/deploying_clearml/clearml_server_aws_ec2_ami/#latest-version))
    ```hcl
    ami_id = "<ami_id>"  # e.g., V1.6.2 ami-0249f03d190062970 for us-east-1 **CHANGE THIS**
    \# instance_type = "t3a.large"  # default
    ```

    \# `apiserver.conf` Settings:
    ```hcl
    user_creds_file = "user_credentials.yaml.philips"  # (DEFAULT)
    ```

9.  Copy `user_credentials.yaml` to `user_credentials.yaml.philips`.  
   Note: `user_credentials.yaml.philips` is added to `.gitignore`.  
   It is your responsibility to handle credentials securely.
10. Configuration files.
    `apiserver.conf` is generated based on `user_credentials.yaml.philips` and stored in S3 bucket `<clearml_tfstate_example>/terraform/CLEARML/server/config/apiserver.conf` and uploaded (SSM) to the clearml server 
    `secure.conf` <key> and <secret> are replaced by tokens and stored in S3 bucket`<clearml_tfstate_example>/terraform/CLEARML/server/config/apiserver.conf` and uploaded (SSM) to the clearml server
11. Run `terraform init`.
12. Run `terraform plan`.
13. Run `terraform apply`.
14. If you receive the following error, the instance was not ready. Run `terraform apply` again:
    ```
    ╷
    │ Error: local-exec provisioner error
    │ 
    │   with null_resource.trigger_ssm,
    │   on provisioner.tf line 24, in resource "null_resource" "trigger_ssm":
    │   24:   provisioner "local-exec" {
    │ 
    │ Error running command 'aws ssm send-command --document-name CopyFileFromS3 --targets 'Key=instanceids,Values=i-xxxxxxxxx'': exit status 254. Output: 
    │ An error occurred (InvalidInstanceId) when calling the SendCommand operation: Instances [[i-xxxxxxxxxx]] not in a valid state for account 767398051271
    │ 
    ╵
    ```

## Onboarding and Offboarding Users

1. Edit `user_credentials.yaml.philips`.
   A change triggers terraform to generate apiserver.conf again, update it in the S3 state bucket and upload it (SSM) to the clearml server
2. Run `terraform plan`.
3. Run `terraform apply`.



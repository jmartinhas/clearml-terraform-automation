#!/bin/env python3
"""
ClearML apiserver.conf S3 Generator Script

This script generates a ClearML apiserver.conf file with user credentials, 
optionally hashes passwords, and uploads the configuration to an S3 bucket. 
It is intended for use in automated Terraform deployments.

Arguments:
    1. enable_hash_arg: 'true' to hash passwords, 'false' to store plain text
    2. tfstate_bucket_arg: S3 bucket name for storing the config
    3. s3_key: S3 object key for the config file
    4. user_credentials_file: Path to YAML file with user credentials
    5. domain_name: Domain for ClearML cookies

Requires: bcrypt, base64, yaml, utils.py (for S3 upload)
"""

import sys
import base64
import bcrypt
import yaml
import utils

enable_hash_arg = str(sys.argv[1])
tfstate_bucket_arg = sys.argv[2]
s3_key = sys.argv[3]
user_credentials_file = sys.argv[4]
domain_name = sys.argv[5]

# Load user credentials from a YAML file
try:
    with open(user_credentials_file, 'r', encoding='utf-8') as f:
        user_credentials_list = yaml.safe_load(f)

except FileNotFoundError:
    print(f"File {user_credentials_file} not found.")
    sys.exit(1)

# Initialize the configuration content
config_content = f"""

auth {{
    cookies {{
        httponly: true
        secure: true
        domain: ".clearml.{domain_name}"
        max_age: 99999999999
    }}
    # Fixed users login credentials
    # No other user will be able to login
    fixed_users {{
        enabled: true
        pass_hashed: {enable_hash_arg}
        users: [
"""


# Iterate over each user in the list and add their credentials to the configuration content
for user_credentials in user_credentials_list['users']:
    username = user_credentials['username']
    password = user_credentials['password']
    name = user_credentials['name']
    hashed_password = password
    if enable_hash_arg == 'true':
        # Hash the password using bcrypt
        hashed_password = base64.b64encode(bcrypt.hashpw(password.encode(), bcrypt.gensalt()))
        hashed_password = hashed_password.decode('utf-8')
    # Add the user's credentials to the configuration content
    config_content += f"""
            {{
                username: "{username}"
                password: "{hashed_password}"
                name: "{name}"
            }},
    """

# Close the configuration content
config_content += """
        ]
    }
}
"""

utils.upload_multiline_text_to_s3(config_content, tfstate_bucket_arg, s3_key)

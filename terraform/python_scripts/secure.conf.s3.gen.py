#!/usr/bin/env python3

"""
ClearML secure.conf S3 Generator Script

This script generates a secure.conf file for ClearML, replacing <secret> and <key> placeholders 
with randomly generated values, and uploads the result to an S3 bucket. 
Intended for use in automated Terraform deployments.

Arguments:
    1. tfstate_bucket_arg: S3 bucket name for storing the config
    2. s3_key: S3 object key for the config file
    3. f_path: Path to the secure.conf template file

Requires: secrets, string, utils.py (for S3 upload)
"""

import secrets
import string
import sys
import utils

tfstate_bucket_arg = sys.argv[1]
s3_key = sys.argv[2]
f_path = sys.argv[3]

def get_random_string(length):
    """
    Create a random crypto-safe sequence of 'length' or more characters
    Possible characters: alphanumeric, '-' and '_'
    Make sure that it starts from alphanumeric for better compatibility with yaml files
    """
    token = secrets.token_urlsafe(length)
    for _ in range(10):
        if not (token.startswith("-") or token.startswith("_")):
            break
        token = secrets.token_urlsafe(length)

    return token

def get_client_id(length: int = 30,
                  allowed_chars: str = string.ascii_uppercase + string.digits) -> str:
    """
    Create a random client id composed of 'length' upper case characters or digits
    """
    return "".join(secrets.choice(allowed_chars) for _ in range(length))

def get_secret_key(length: int = 50) -> str:
    """
    Create a random secret key
    """
    return get_random_string(length)

def replace_item(content, item_name, function):
    """
    Replaces placeholders in a given content with randomly generated values.

    Args:
        content (str): The content to modify.
        item_name (str): The name of the placeholder to replace.
        function (function): A function that generates the replacement value.

    Returns:
        str: The modified content with placeholders replaced.
    """
    item_content = ""
    parts = content.split("<" + item_name + ">")
    for i in range(len(parts) - 1):
        item_content += parts[i] + function()
    item_content += parts[-1]
    return item_content

def replace_secret_key_in_file(file_path=f_path):
    """
    Replaces placeholders in a given content with randomly generated values.

    Args:
        file_path (str): The path to the secure configuration file.

    Returns:
        str: The modified content with placeholders replaced.
    """
    # Read the file content
    with open(file_path, 'r', encoding='utf-8') as file:
        content = file.read()

    replace_secret_content = replace_item(content, "secret", get_secret_key)
    replace_key_conent = replace_item(replace_secret_content, "key", get_client_id)
    return replace_key_conent

config_content = replace_secret_key_in_file()
utils.upload_multiline_text_to_s3(config_content, tfstate_bucket_arg, s3_key)
utils.upload_multiline_text_to_s3(config_content, tfstate_bucket_arg, s3_key)

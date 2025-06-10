"""
Module containing utility functions for interacting with AWS services.

Functions:
    - upload_multiline_text_to_s3: Uploads multiline text to an S3 bucket.
"""
import boto3
from botocore.exceptions import NoCredentialsError, PartialCredentialsError

def upload_multiline_text_to_s3(content, bucket_name, key):
    """
    Uploads multiline text to an S3 bucket.

    Args:
        content (str): The content to be uploaded.
        bucket_name (str): The name of the S3 bucket.
        key (str): The key for the object in the S3 bucket.

    Returns:
        None
    """
    try:
        s3 = boto3.client('s3')
        print(f'Uploading contents to {bucket_name}/{key}')
        s3.put_object(Bucket=bucket_name, Key=key, Body=content)
        print(f'Contents uploaded to {bucket_name}/{key}')
    except NoCredentialsError:
        print('Credentials not available')
    except PartialCredentialsError:
        print('Incomplete credentials provided')

    print(f"Configuration file {key} has been uploaded to S3 state bucket {bucket_name} successfully.")

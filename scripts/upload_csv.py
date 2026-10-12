# Usage: python scripts/upload_csv.py <file path> <env>
# Example: python scripts/upload_csv.py data/transactions_20260901.csv dev
import os
import sys

import boto3

file_path = sys.argv[1]  # file on this machine
env = sys.argv[2]  # dev, test or prod

bucket = "kb-data-pipeline-landing-hravat-" + env
name = os.path.basename(file_path)  # transactions_20260901.csv
date = name.split("_")[1].split(".")[0]  # 20260901
key = f"transactions/{date[:4]}/{date[4:6]}/{date[6:]}/{name}"  # transactions/2026/09/01/...

boto3.client("s3").upload_file(file_path, bucket, key)
print(f"Uploaded {file_path} to s3://{bucket}/{key}")

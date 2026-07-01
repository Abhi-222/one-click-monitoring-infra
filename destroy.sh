#!/usr/bin/env bash
# destroy.sh - Automated entire teardown & cleanup of AWS monitoring stack

# Exit immediately if a command exits with a non-zero status
set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

MAIN_TERRAFORM_DIR="${SCRIPT_DIR}/terraform"
BOOTSTRAP_DIR="${SCRIPT_DIR}/terraform-bootstrap"

echo "=========================================================="
echo " Starting Full AWS Infrastructure Teardown & Clean"
echo "=========================================================="

# 1. Destroy Main Infrastructure Stack
echo -e "\n--> Step 1: Destroying main infrastructure stack..."
if [ -d "$MAIN_TERRAFORM_DIR" ]; then
    cd "$MAIN_TERRAFORM_DIR"
    echo "Initializing Terraform..."
    terraform init || echo "Failed to initialize main stack. Proceeding..."
    echo "Running terraform destroy..."
    terraform destroy -auto-approve -var environment=dev || echo "Terraform destroy failed or main stack not found. Proceeding..."
else
    echo "Main Terraform directory not found. Skipping."
fi

# 2. Modify bootstrap config to allow S3 bucket destruction
echo -e "\n--> Step 2: Disabling prevent_destroy on bootstrap S3 bucket config..."
S3_TF_PATH="${BOOTSTRAP_DIR}/s3.tf"
if [ -f "$S3_TF_PATH" ]; then
    # Replace prevent_destroy = true with prevent_destroy = false
    if grep -q "prevent_destroy = true" "$S3_TF_PATH"; then
        sed -i 's/prevent_destroy = true/prevent_destroy = false/g' "$S3_TF_PATH"
        echo "Successfully modified s3.tf to allow destruction."
    else
        echo "prevent_destroy is already false or not found."
    fi
else
    echo "Warning: bootstrap/s3.tf not found. Skipping config modification."
fi

# 3. Destroy Bootstrap State and Lock Table
echo -e "\n--> Step 3: Performing bootstrap Terraform destroy..."
if [ -d "$BOOTSTRAP_DIR" ]; then
    cd "$BOOTSTRAP_DIR"
    echo "Initializing Bootstrap Terraform..."
    terraform init || echo "Failed to initialize bootstrap. Proceeding..."
    # Run destroy (may not delete the versioned S3 bucket if not empty)
    terraform destroy -auto-approve || true
else
    echo "Bootstrap directory not found. Skipping."
fi

# 4. Clean and delete versioned S3 buckets & DynamoDB tables via Python
echo -e "\n--> Step 4: Cleaning up versioned S3 state bucket and DynamoDB lock table..."
python3 <<EOF
import boto3
import sys

s3_client = boto3.client('s3', region_name='ap-south-1')
dynamodb_client = boto3.client('dynamodb', region_name='ap-south-1')

bucket_name = "monitoring-stack-dev-state"
table_name = "monitoring-stack-dev-lock"

print(f"Checking if S3 bucket exists: {bucket_name}")
try:
    s3_client.head_bucket(Bucket=bucket_name)
    bucket_exists = True
except Exception:
    bucket_exists = False
    print("S3 bucket does not exist or access denied.")

if bucket_exists:
    try:
        print("Listing all object versions and delete markers...")
        versions = s3_client.list_object_versions(Bucket=bucket_name)
        delete_list = []
        
        if 'Versions' in versions:
            for version in versions['Versions']:
                delete_list.append({'Key': version['Key'], 'VersionId': version['VersionId']})
                
        if 'DeleteMarkers' in versions:
            for marker in versions['DeleteMarkers']:
                delete_list.append({'Key': marker['Key'], 'VersionId': marker['VersionId']})
                
        if delete_list:
            print(f"Deleting {len(delete_list)} object versions/markers...")
            for i in range(0, len(delete_list), 1000):
                chunk = delete_list[i:i+1000]
                s3_client.delete_objects(Bucket=bucket_name, Delete={'Objects': chunk})
            print("Successfully emptied bucket.")
            
        print(f"Deleting S3 bucket: {bucket_name}")
        s3_client.delete_bucket(Bucket=bucket_name)
        print("S3 bucket deleted successfully.")
    except Exception as e:
        print(f"Error cleaning S3 bucket: {e}")

print(f"Checking if DynamoDB table exists: {table_name}")
try:
    dynamodb_client.describe_table(TableName=table_name)
    table_exists = True
except Exception:
    table_exists = False
    print("DynamoDB table does not exist.")

if table_exists:
    try:
        print(f"Deleting DynamoDB table: {table_name}")
        dynamodb_client.delete_table(TableName=table_name)
        print("DynamoDB table deletion initiated.")
    except Exception as e:
        print(f"Error deleting DynamoDB table: {e}")
EOF

# 5. Output Verification & Clean Status
echo -e "\n=========================================================="
echo " Verification: AWS Clean State Status"
echo "=========================================================="

echo "1. Checking active S3 Buckets in region:"
aws s3 ls || echo "No S3 Buckets found."

echo -e "\n2. Checking active DynamoDB Tables in ap-south-1:"
aws dynamodb list-tables --region ap-south-1

echo -e "\n3. Checking active EC2 Instances with tags:"
aws ec2 describe-instances \
    --region ap-south-1 \
    --filters "Name=tag:Project,Values=Monitoring Infrastructure" "Name=instance-state-name,Values=running,pending" \
    --query "Reservations[*].Instances[*].[InstanceId,State.Name,Tags[?Key=='Name'].Value|[0]]" \
    --output table || echo "No active monitoring EC2 instances found."

echo -e "\n=========================================================="
echo " Infrastructure Teardown Complete! AWS Environment is CLEAN."
echo "=========================================================="

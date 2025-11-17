#!/bin/bash
# Script to set up S3 backend for Terraform state management
# This should be run ONCE before using Terraform

set -e

REGION="us-east-1"
PROJECT_NAME="devops-workshop"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Setting up Terraform backend infrastructure...${NC}"

# Create S3 buckets for each environment
for ENV in dev staging prod; do
    BUCKET_NAME="${PROJECT_NAME}-terraform-state-${ENV}"
    
    echo -e "${YELLOW}Creating S3 bucket: ${BUCKET_NAME}${NC}"
    
    # Create bucket
    aws s3api create-bucket \
        --bucket ${BUCKET_NAME} \
        --region ${REGION} 2>/dev/null || echo "Bucket already exists"
    
    # Enable versioning
    aws s3api put-bucket-versioning \
        --bucket ${BUCKET_NAME} \
        --versioning-configuration Status=Enabled
    
    # Enable encryption
    aws s3api put-bucket-encryption \
        --bucket ${BUCKET_NAME} \
        --server-side-encryption-configuration '{
            "Rules": [{
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }]
        }'
    
    # Block public access
    aws s3api put-public-access-block \
        --bucket ${BUCKET_NAME} \
        --public-access-block-configuration \
            "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
    
    # Enable logging
    aws s3api put-bucket-logging \
        --bucket ${BUCKET_NAME} \
        --bucket-logging-status '{
            "LoggingEnabled": {
                "TargetBucket": "'${BUCKET_NAME}'",
                "TargetPrefix": "logs/"
            }
        }' 2>/dev/null || echo "Logging configuration skipped"
    
    echo -e "${GREEN}✓ Bucket ${BUCKET_NAME} configured${NC}"
done

# Create DynamoDB table for state locking
TABLE_NAME="terraform-state-lock"
echo -e "${YELLOW}Creating DynamoDB table: ${TABLE_NAME}${NC}"

aws dynamodb create-table \
    --table-name ${TABLE_NAME} \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region ${REGION} 2>/dev/null || echo "Table already exists"

echo -e "${GREEN}✓ DynamoDB table ${TABLE_NAME} created${NC}"

echo ""
echo -e "${GREEN}Backend setup complete!${NC}"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Uncomment the backend block in each environment's main.tf"
echo "2. Run: terraform init"
echo "3. Confirm state migration when prompted"

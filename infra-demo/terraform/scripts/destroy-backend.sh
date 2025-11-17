#!/bin/bash
# Destroy backend infrastructure (USE WITH CAUTION!)

set -e

REGION="us-east-1"
PROJECT_NAME="devops-workshop"

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${RED}WARNING: This will destroy all Terraform state infrastructure!${NC}"
echo -e "${YELLOW}This should only be done when completely decommissioning the project.${NC}"
read -p "Type 'DESTROY' to continue: " confirm

if [ "$confirm" != "DESTROY" ]; then
    echo "Cancelled"
    exit 0
fi

# Delete S3 buckets
for ENV in dev staging prod; do
    BUCKET_NAME="${PROJECT_NAME}-terraform-state-${ENV}"
    echo "Deleting bucket: ${BUCKET_NAME}"
    
    # Delete all versions and delete markers
    aws s3api delete-objects \
        --bucket ${BUCKET_NAME} \
        --delete "$(aws s3api list-object-versions \
        --bucket ${BUCKET_NAME} \
        --query '{Objects: Versions[].{Key:Key,VersionId:VersionId}}' \
        --max-items 1000)" 2>/dev/null || true
    
    aws s3 rb s3://${BUCKET_NAME} --force 2>/dev/null || true
done

# Delete DynamoDB table
echo "Deleting DynamoDB table: terraform-state-lock"
aws dynamodb delete-table --table-name terraform-state-lock --region ${REGION} 2>/dev/null || true

echo "Backend infrastructure destroyed"

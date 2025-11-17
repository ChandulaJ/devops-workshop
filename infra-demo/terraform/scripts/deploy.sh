#!/bin/bash
# Deployment script for specific environment

set -e

ENVIRONMENT=$1

if [ -z "$ENVIRONMENT" ]; then
    echo "Usage: $0 <environment>"
    echo "Environments: dev, staging, production"
    exit 1
fi

if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|production)$ ]]; then
    echo "Invalid environment. Use: dev, staging, or production"
    exit 1
fi

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}Deploying to: ${ENVIRONMENT}${NC}"

cd "$(dirname "$0")/../environments/${ENVIRONMENT}"

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo -e "${YELLOW}terraform.tfvars not found. Creating from example...${NC}"
    cp terraform.tfvars.example terraform.tfvars
    echo -e "${YELLOW}Please edit terraform.tfvars before continuing${NC}"
    exit 1
fi

# Initialize
echo -e "${GREEN}Initializing Terraform...${NC}"
terraform init

# Validate
echo -e "${GREEN}Validating configuration...${NC}"
terraform validate

# Plan
echo -e "${GREEN}Creating execution plan...${NC}"
terraform plan -out=tfplan

# Apply (with confirmation)
if [ "$ENVIRONMENT" == "production" ]; then
    echo -e "${YELLOW}PRODUCTION DEPLOYMENT - Extra confirmation required${NC}"
    read -p "Type 'yes' to deploy to production: " confirm
    if [ "$confirm" != "yes" ]; then
        echo "Deployment cancelled"
        exit 1
    fi
fi

echo -e "${GREEN}Applying changes...${NC}"
terraform apply tfplan

# Show outputs
echo -e "${GREEN}Deployment complete! Outputs:${NC}"
terraform output

# Cleanup plan file
rm -f tfplan

echo ""
echo -e "${GREEN}Next steps:${NC}"
echo "1. Review the outputs above"
echo "2. Run Ansible playbook: cd ../../../ansible && ansible-playbook -i inventory/${ENVIRONMENT}/hosts playbook.yml"
echo "3. Verify deployment"

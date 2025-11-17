#!/bin/bash
# Destroy resources in specific environment

set -e

ENVIRONMENT=$1

if [ -z "$ENVIRONMENT" ]; then
    echo "Usage: $0 <environment>"
    echo "Environments: dev, staging, production"
    exit 1
fi

RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

cd "$(dirname "$0")/../environments/${ENVIRONMENT}"

echo -e "${RED}WARNING: This will destroy all resources in ${ENVIRONMENT}!${NC}"
read -p "Type '${ENVIRONMENT}' to confirm: " confirm

if [ "$confirm" != "${ENVIRONMENT}" ]; then
    echo "Cancelled"
    exit 0
fi

if [ "$ENVIRONMENT" == "production" ]; then
    echo -e "${RED}PRODUCTION DESTRUCTION - Final confirmation${NC}"
    read -p "Type 'DESTROY PRODUCTION' to proceed: " final
    if [ "$final" != "DESTROY PRODUCTION" ]; then
        echo "Cancelled"
        exit 0
    fi
fi

terraform destroy

echo -e "${YELLOW}Resources destroyed for ${ENVIRONMENT}${NC}"

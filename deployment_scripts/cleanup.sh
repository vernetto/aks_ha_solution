#!/bin/bash
# Cleanup script for AKS High Availability Solution
# This script automates the cleanup of the entire infrastructure

set -e

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print header
echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}   AKS High Availability Solution Cleanup         ${NC}"
echo -e "${GREEN}==================================================${NC}"

# Check for required tools
echo -e "\n${YELLOW}Checking for required tools...${NC}"
command -v az >/dev/null 2>&1 || { echo -e "${RED}Error: Azure CLI is required but not installed.${NC}"; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo -e "${RED}Error: Terraform is required but not installed.${NC}"; exit 1; }
echo -e "${GREEN}All required tools are installed.${NC}"

# Login to Azure
echo -e "\n${YELLOW}Logging in to Azure...${NC}"
az login --use-device-code
az account show

# Set variables
echo -e "\n${YELLOW}Setting up variables...${NC}"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TERRAFORM_DIR="./infrastructure_code"
EAST_RESOURCE_GROUP="rg-aks-ha-eastus"
WEST_RESOURCE_GROUP="rg-aks-ha-westus"

# Set subscription
echo -e "\n${YELLOW}Setting Azure subscription...${NC}"
az account set --subscription $SUBSCRIPTION_ID

# Confirm cleanup
echo -e "\n${RED}WARNING: This will destroy all resources created by the deployment script.${NC}"
read -p "Are you sure you want to proceed? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
    echo -e "${YELLOW}Cleanup aborted.${NC}"
    exit 0
fi

# Initialize Terraform
echo -e "\n${YELLOW}Initializing Terraform...${NC}"
cd $TERRAFORM_DIR
terraform init

# Destroy infrastructure
echo -e "\n${YELLOW}Destroying infrastructure with Terraform...${NC}"
terraform destroy -auto-approve

echo -e "\n${GREEN}==================================================${NC}"
echo -e "${GREEN}   Cleanup Complete!                             ${NC}"
echo -e "${GREEN}==================================================${NC}"
echo -e "\n${GREEN}All resources have been successfully removed.${NC}"

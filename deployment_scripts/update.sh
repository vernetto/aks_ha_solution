#!/bin/bash
# Update script for AKS High Availability Solution
# This script helps update the deployed application

set -e

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print header
echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}   AKS High Availability Solution Update          ${NC}"
echo -e "${GREEN}==================================================${NC}"

# Check for required tools
echo -e "\n${YELLOW}Checking for required tools...${NC}"
command -v az >/dev/null 2>&1 || { echo -e "${RED}Error: Azure CLI is required but not installed.${NC}"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}Error: kubectl is required but not installed.${NC}"; exit 1; }
command -v docker >/dev/null 2>&1 || { echo -e "${RED}Error: Docker is required but not installed.${NC}"; exit 1; }
echo -e "${GREEN}All required tools are installed.${NC}"

# Check parameters
if [ "$#" -lt 2 ]; then
    echo -e "${RED}Usage: $0 <component> <version>${NC}"
    echo -e "${YELLOW}component: webapp or database${NC}"
    echo -e "${YELLOW}version: new version tag${NC}"
    exit 1
fi

COMPONENT=$1
VERSION=$2

# Login to Azure
echo -e "\n${YELLOW}Logging in to Azure...${NC}"
az login --use-device-code
az account show

# Set variables
echo -e "\n${YELLOW}Setting up variables...${NC}"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
EAST_RESOURCE_GROUP="rg-aks-ha-eastus"
WEST_RESOURCE_GROUP="rg-aks-ha-westus"

# Set subscription
echo -e "\n${YELLOW}Setting Azure subscription...${NC}"
az account set --subscription $SUBSCRIPTION_ID

# Get ACR details
echo -e "\n${YELLOW}Getting ACR details...${NC}"
ACR_NAME=$(az acr list --query '[0].name' -o tsv)
ACR_LOGIN_SERVER=$(az acr list --query '[0].loginServer' -o tsv)

# Login to ACR
echo -e "\n${YELLOW}Logging in to ACR...${NC}"
az acr login --name $ACR_NAME

# Build and push Docker image
echo -e "\n${YELLOW}Building and pushing Docker image for $COMPONENT:$VERSION...${NC}"
if [ -d "./$COMPONENT" ]; then
    cd ./$COMPONENT
    docker build -t $ACR_LOGIN_SERVER/$COMPONENT:$VERSION .
    docker push $ACR_LOGIN_SERVER/$COMPONENT:$VERSION
    cd ..
else
    echo -e "${RED}Error: $COMPONENT directory not found.${NC}"
    exit 1
fi

# Get AKS cluster names
echo -e "\n${YELLOW}Getting AKS cluster names...${NC}"
EAST_AKS_NAME=$(az aks list -g $EAST_RESOURCE_GROUP --query '[0].name' -o tsv)
WEST_AKS_NAME=$(az aks list -g $WEST_RESOURCE_GROUP --query '[0].name' -o tsv)

# Update East US cluster
echo -e "\n${YELLOW}Updating $COMPONENT in East US cluster...${NC}"
az aks get-credentials --resource-group $EAST_RESOURCE_GROUP --name $EAST_AKS_NAME --overwrite-existing --admin

if [ "$COMPONENT" == "webapp" ]; then
    kubectl set image deployment/webapp webapp=$ACR_LOGIN_SERVER/webapp:$VERSION -n webapp
    kubectl rollout status deployment/webapp -n webapp
elif [ "$COMPONENT" == "database" ]; then
    kubectl set image statefulset/database database=$ACR_LOGIN_SERVER/database:$VERSION -n database
    kubectl rollout status statefulset/database -n database
else
    echo -e "${RED}Error: Unknown component $COMPONENT.${NC}"
    exit 1
fi

# Update West US cluster
echo -e "\n${YELLOW}Updating $COMPONENT in West US cluster...${NC}"
az aks get-credentials --resource-group $WEST_RESOURCE_GROUP --name $WEST_AKS_NAME --overwrite-existing --admin --file ./west-kubeconfig
export KUBECONFIG="./west-kubeconfig"

if [ "$COMPONENT" == "webapp" ]; then
    kubectl set image deployment/webapp webapp=$ACR_LOGIN_SERVER/webapp:$VERSION -n webapp
    kubectl rollout status deployment/webapp -n webapp
elif [ "$COMPONENT" == "database" ]; then
    kubectl set image statefulset/database database=$ACR_LOGIN_SERVER/database:$VERSION -n database
    kubectl rollout status statefulset/database -n database
fi

# Reset KUBECONFIG
export KUBECONFIG=""

echo -e "\n${GREEN}==================================================${NC}"
echo -e "${GREEN}   Update Complete!                              ${NC}"
echo -e "${GREEN}==================================================${NC}"
echo -e "\n${GREEN}$COMPONENT has been updated to version $VERSION in both regions.${NC}"

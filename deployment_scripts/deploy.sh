#!/bin/bash
# Deployment script for AKS High Availability Solution
# This script automates the deployment of the entire infrastructure and application

set -e

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print header
echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}   AKS High Availability Solution Deployment      ${NC}"
echo -e "${GREEN}==================================================${NC}"

# Check for required tools
echo -e "\n${YELLOW}Checking for required tools...${NC}"
command -v az >/dev/null 2>&1 || { echo -e "${RED}Error: Azure CLI is required but not installed. Visit https://docs.microsoft.com/en-us/cli/azure/install-azure-cli${NC}"; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo -e "${RED}Error: Terraform is required but not installed. Visit https://www.terraform.io/downloads.html${NC}"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}Error: kubectl is required but not installed. Visit https://kubernetes.io/docs/tasks/tools/install-kubectl/${NC}"; exit 1; }
echo -e "${GREEN}All required tools are installed.${NC}"

# Login to Azure
echo -e "\n${YELLOW}Logging in to Azure...${NC}"
az login --use-device-code
az account show

# Set variables
echo -e "\n${YELLOW}Setting up variables...${NC}"
SUBSCRIPTION_ID=$(az account show --query id -o tsv)
TERRAFORM_DIR="./infrastructure_code"
K8S_MANIFESTS_DIR="./k8s_manifests"
EAST_RESOURCE_GROUP="rg-aks-ha-eastus"
WEST_RESOURCE_GROUP="rg-aks-ha-westus"

# Set subscription
echo -e "\n${YELLOW}Setting Azure subscription...${NC}"
az account set --subscription $SUBSCRIPTION_ID

# Initialize Terraform
echo -e "\n${YELLOW}Initializing Terraform...${NC}"
cd $TERRAFORM_DIR
terraform init

# Validate Terraform configuration
echo -e "\n${YELLOW}Validating Terraform configuration...${NC}"
terraform validate

# Plan Terraform deployment
echo -e "\n${YELLOW}Planning Terraform deployment...${NC}"
terraform plan -out=tfplan

# Apply Terraform deployment
echo -e "\n${YELLOW}Deploying infrastructure with Terraform...${NC}"
terraform apply -auto-approve tfplan

# Get AKS credentials for East US cluster
echo -e "\n${YELLOW}Getting AKS credentials for East US cluster...${NC}"
EAST_AKS_NAME=$(terraform output -raw aks_east_id | awk -F'/' '{print $NF}')
az aks get-credentials --resource-group $EAST_RESOURCE_GROUP --name $EAST_AKS_NAME --overwrite-existing --admin

# Get AKS credentials for West US cluster
echo -e "\n${YELLOW}Getting AKS credentials for West US cluster...${NC}"
WEST_AKS_NAME=$(terraform output -raw aks_west_id | awk -F'/' '{print $NF}')
az aks get-credentials --resource-group $WEST_RESOURCE_GROUP --name $WEST_AKS_NAME --overwrite-existing --admin --file ./west-kubeconfig
export KUBECONFIG_WEST="./west-kubeconfig"

# Get ACR details
echo -e "\n${YELLOW}Getting ACR details...${NC}"
ACR_NAME=$(terraform output -raw acr_login_server | awk -F'.' '{print $1}')

# Attach ACR to AKS clusters
echo -e "\n${YELLOW}Attaching ACR to AKS clusters...${NC}"
az aks update -n $EAST_AKS_NAME -g $EAST_RESOURCE_GROUP --attach-acr $ACR_NAME
az aks update -n $WEST_AKS_NAME -g $WEST_RESOURCE_GROUP --attach-acr $ACR_NAME

# Deploy Kubernetes manifests to East US cluster
echo -e "\n${YELLOW}Deploying Kubernetes manifests to East US cluster...${NC}"
cd ../$K8S_MANIFESTS_DIR

# Replace ACR placeholder in manifests
find . -type f -name "*.yaml" -exec sed -i "s/\${ACR_NAME}/$ACR_NAME/g" {} \;

# Create namespaces
kubectl apply -f namespace.yaml
kubectl apply -f database-namespace.yaml

# Deploy ConfigMaps and Secrets
kubectl apply -f webapp-configmap.yaml
kubectl apply -f webapp-secrets.yaml
kubectl apply -f database-configmap.yaml
kubectl apply -f database-secrets.yaml

# Deploy database components
kubectl apply -f database-statefulset.yaml
kubectl apply -f database-service.yaml

# Deploy web application components
kubectl apply -f webapp-deployment.yaml
kubectl apply -f webapp-service.yaml
kubectl apply -f webapp-ingress.yaml

# Deploy Kubernetes manifests to West US cluster
echo -e "\n${YELLOW}Deploying Kubernetes manifests to West US cluster...${NC}"
export KUBECONFIG=$KUBECONFIG_WEST

# Create namespaces
kubectl apply -f namespace.yaml
kubectl apply -f database-namespace.yaml

# Deploy ConfigMaps and Secrets
kubectl apply -f webapp-configmap.yaml
kubectl apply -f webapp-secrets.yaml
kubectl apply -f database-configmap.yaml
kubectl apply -f database-secrets.yaml

# Deploy database components
kubectl apply -f database-statefulset.yaml
kubectl apply -f database-service.yaml

# Deploy web application components
kubectl apply -f webapp-deployment.yaml
kubectl apply -f webapp-service.yaml
kubectl apply -f webapp-ingress.yaml

# Reset KUBECONFIG
export KUBECONFIG=""

# Print deployment information
echo -e "\n${GREEN}==================================================${NC}"
echo -e "${GREEN}   Deployment Complete!                           ${NC}"
echo -e "${GREEN}==================================================${NC}"
echo -e "\n${YELLOW}Front Door Endpoint:${NC}"
cd ../$TERRAFORM_DIR
terraform output frontdoor_endpoint

echo -e "\n${YELLOW}SQL Failover Group FQDN:${NC}"
terraform output sql_failover_group_fqdn

echo -e "\n${YELLOW}To access East US AKS cluster:${NC}"
echo "az aks get-credentials --resource-group $EAST_RESOURCE_GROUP --name $EAST_AKS_NAME --admin"

echo -e "\n${YELLOW}To access West US AKS cluster:${NC}"
echo "az aks get-credentials --resource-group $WEST_RESOURCE_GROUP --name $WEST_AKS_NAME --admin"

echo -e "\n${GREEN}Deployment completed successfully!${NC}"

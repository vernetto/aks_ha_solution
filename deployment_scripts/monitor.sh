#!/bin/bash
# Monitoring script for AKS High Availability Solution
# This script helps monitor the health of the deployed infrastructure

set -e

# Color codes for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Print header
echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}   AKS High Availability Solution Monitoring      ${NC}"
echo -e "${GREEN}==================================================${NC}"

# Check for required tools
echo -e "\n${YELLOW}Checking for required tools...${NC}"
command -v az >/dev/null 2>&1 || { echo -e "${RED}Error: Azure CLI is required but not installed.${NC}"; exit 1; }
command -v kubectl >/dev/null 2>&1 || { echo -e "${RED}Error: kubectl is required but not installed.${NC}"; exit 1; }
echo -e "${GREEN}All required tools are installed.${NC}"

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

# Get AKS cluster names
echo -e "\n${YELLOW}Getting AKS cluster names...${NC}"
EAST_AKS_NAME=$(az aks list -g $EAST_RESOURCE_GROUP --query '[0].name' -o tsv)
WEST_AKS_NAME=$(az aks list -g $WEST_RESOURCE_GROUP --query '[0].name' -o tsv)

# Get AKS credentials for East US cluster
echo -e "\n${YELLOW}Getting AKS credentials for East US cluster...${NC}"
az aks get-credentials --resource-group $EAST_RESOURCE_GROUP --name $EAST_AKS_NAME --overwrite-existing --admin

# Check East US cluster health
echo -e "\n${YELLOW}Checking East US cluster health...${NC}"
echo -e "\n${YELLOW}Nodes:${NC}"
kubectl get nodes -o wide

echo -e "\n${YELLOW}Pods in webapp namespace:${NC}"
kubectl get pods -n webapp -o wide

echo -e "\n${YELLOW}Pods in database namespace:${NC}"
kubectl get pods -n database -o wide

echo -e "\n${YELLOW}Services:${NC}"
kubectl get services --all-namespaces

echo -e "\n${YELLOW}Ingress:${NC}"
kubectl get ingress --all-namespaces

# Get AKS credentials for West US cluster
echo -e "\n${YELLOW}Getting AKS credentials for West US cluster...${NC}"
az aks get-credentials --resource-group $WEST_RESOURCE_GROUP --name $WEST_AKS_NAME --overwrite-existing --admin --file ./west-kubeconfig
export KUBECONFIG="./west-kubeconfig"

# Check West US cluster health
echo -e "\n${YELLOW}Checking West US cluster health...${NC}"
echo -e "\n${YELLOW}Nodes:${NC}"
kubectl get nodes -o wide

echo -e "\n${YELLOW}Pods in webapp namespace:${NC}"
kubectl get pods -n webapp -o wide

echo -e "\n${YELLOW}Pods in database namespace:${NC}"
kubectl get pods -n database -o wide

echo -e "\n${YELLOW}Services:${NC}"
kubectl get services --all-namespaces

echo -e "\n${YELLOW}Ingress:${NC}"
kubectl get ingress --all-namespaces

# Reset KUBECONFIG
export KUBECONFIG=""

# Check Front Door health
echo -e "\n${YELLOW}Checking Front Door health...${NC}"
FRONTDOOR_NAME=$(az network front-door list --query '[0].name' -o tsv)
if [ ! -z "$FRONTDOOR_NAME" ]; then
  az network front-door show --name $FRONTDOOR_NAME --resource-group $EAST_RESOURCE_GROUP --query 'routingRules[0].frontendEndpoints[0].name' -o tsv
  echo -e "${GREEN}Front Door is healthy.${NC}"
else
  echo -e "${RED}Front Door not found.${NC}"
fi

# Check SQL Database health
echo -e "\n${YELLOW}Checking SQL Database health...${NC}"
SQL_SERVER_EAST=$(az sql server list -g $EAST_RESOURCE_GROUP --query '[0].name' -o tsv)
SQL_SERVER_WEST=$(az sql server list -g $WEST_RESOURCE_GROUP --query '[0].name' -o tsv)

if [ ! -z "$SQL_SERVER_EAST" ] && [ ! -z "$SQL_SERVER_WEST" ]; then
  FAILOVER_GROUP=$(az sql failover-group list --server $SQL_SERVER_EAST -g $EAST_RESOURCE_GROUP --query '[0].name' -o tsv)
  if [ ! -z "$FAILOVER_GROUP" ]; then
    az sql failover-group show --name $FAILOVER_GROUP --server $SQL_SERVER_EAST -g $EAST_RESOURCE_GROUP --query 'replicationState' -o tsv
    echo -e "${GREEN}SQL Failover Group is healthy.${NC}"
  else
    echo -e "${RED}SQL Failover Group not found.${NC}"
  fi
else
  echo -e "${RED}SQL Servers not found.${NC}"
fi

echo -e "\n${GREEN}==================================================${NC}"
echo -e "${GREEN}   Monitoring Complete!                           ${NC}"
echo -e "${GREEN}==================================================${NC}"

# Deployment Guide for Azure AKS High Availability Solution

This guide provides step-by-step instructions for deploying the highly available web application with load balancing and database integration on Azure Kubernetes Service (AKS).

## Prerequisites

Before beginning the deployment, ensure you have the following:

1. **Azure Subscription**: An active Azure subscription with sufficient permissions to create resources
2. **Required Tools**:
   - Azure CLI (latest version)
   - Terraform (version 1.0 or later)
   - kubectl (compatible with your AKS version)
   - Docker (for building and pushing container images)
3. **Domain Name**: (Optional) A custom domain name if you want to use your own domain instead of the Azure Front Door default domain

## Step 1: Prepare Your Environment

1. Clone the repository containing the solution files:
   ```bash
   git clone <repository-url>
   cd aks-ha-solution
   ```

2. Make the deployment scripts executable:
   ```bash
   chmod +x deployment_scripts/*.sh
   ```

3. Log in to Azure:
   ```bash
   az login
   ```

4. Set your subscription:
   ```bash
   az account set --subscription <subscription-id>
   ```

## Step 2: Customize Configuration (Optional)

If you need to customize the deployment, you can modify the following files:

1. **Terraform Variables**: Edit `infrastructure_code/variables.tf` to change default values
   - Resource group locations
   - Kubernetes version
   - Node counts and VM sizes
   - Other configuration parameters

2. **Kubernetes Manifests**: Edit files in the `k8s_manifests` directory
   - Replica counts
   - Resource requests and limits
   - Configuration settings

## Step 3: Deploy the Infrastructure

Run the deployment script to create all required infrastructure and deploy the application:

```bash
./deployment_scripts/deploy.sh
```

This script will:
1. Check for required tools
2. Initialize and apply Terraform to create the infrastructure
3. Get AKS credentials for both clusters
4. Deploy Kubernetes manifests to both clusters
5. Output the deployment information

The deployment process takes approximately 30-45 minutes to complete.

## Step 4: Verify the Deployment

After deployment completes, verify that all components are running correctly:

1. Access the Azure Front Door endpoint provided in the deployment output:
   ```
   https://fd-aks-ha-webapp.azurefd.net
   ```

2. Run the monitoring script to check the health of all components:
   ```bash
   ./deployment_scripts/monitor.sh
   ```

3. Verify that pods are running in both clusters:
   ```bash
   # East US cluster
   kubectl get pods -n webapp
   kubectl get pods -n database

   # West US cluster (using the provided kubeconfig)
   KUBECONFIG=./west-kubeconfig kubectl get pods -n webapp
   KUBECONFIG=./west-kubeconfig kubectl get pods -n database
   ```

## Step 5: Configure Custom Domain (Optional)

If you want to use a custom domain instead of the Azure Front Door default domain:

1. Add a CNAME record in your DNS provider pointing to the Azure Front Door endpoint
   - Record: `webapp.yourdomain.com`
   - Value: `fd-aks-ha-webapp.azurefd.net`

2. Configure the custom domain in Azure Front Door:
   ```bash
   az network front-door frontend-endpoint create \
     --front-door-name fd-aks-ha-webapp \
     --resource-group rg-aks-ha-eastus \
     --name customdomain \
     --host-name webapp.yourdomain.com
   ```

3. Enable HTTPS for the custom domain:
   ```bash
   az network front-door frontend-endpoint enable-https \
     --front-door-name fd-aks-ha-webapp \
     --resource-group rg-aks-ha-eastus \
     --name customdomain
   ```

## Step 6: Update the Application

When you need to update the application, use the update script:

```bash
./deployment_scripts/update.sh webapp 2.0.0
```

This will:
1. Build and push a new container image with the specified version
2. Update the deployment in both clusters
3. Perform a rolling update to ensure zero downtime

## Step 7: Monitor the Solution

For ongoing monitoring:

1. Use the monitoring script for a quick health check:
   ```bash
   ./deployment_scripts/monitor.sh
   ```

2. Access the Azure Portal to view:
   - Azure Monitor dashboards
   - Container Insights
   - Log Analytics workspaces
   - Application Insights

3. Set up alerts for critical metrics:
   ```bash
   # Example: Create an alert for high CPU usage
   az monitor metrics alert create \
     --name "High CPU Alert" \
     --resource-group rg-aks-ha-eastus \
     --scopes <aks-cluster-resource-id> \
     --condition "avg Percentage CPU > 80" \
     --window-size 5m \
     --evaluation-frequency 1m \
     --action <action-group-id>
   ```

## Troubleshooting

### Common Issues

1. **Deployment Failures**:
   - Check Terraform logs for infrastructure issues
   - Verify Azure resource quotas and limits
   - Check network connectivity between components

2. **Application Not Accessible**:
   - Verify Front Door configuration
   - Check Application Gateway health
   - Inspect Kubernetes service and ingress configurations

3. **Database Connectivity Issues**:
   - Verify SQL Server firewall rules
   - Check connection strings in application configuration
   - Inspect network security group rules

### Getting Support

For additional support:
- Review the full documentation in `docs/documentation.md`
- Check Azure status page for service outages
- Contact Azure support for infrastructure issues
- Refer to the project repository for known issues and solutions

## Cleanup

When you no longer need the solution, use the cleanup script to remove all resources:

```bash
./deployment_scripts/cleanup.sh
```

This will destroy all created infrastructure and remove all resources from both regions.

**Note**: This action is irreversible and will delete all data. Make sure to back up any important information before running the cleanup script.

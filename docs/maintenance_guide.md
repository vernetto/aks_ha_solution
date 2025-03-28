# Maintenance Guide for Azure AKS High Availability Solution

This guide provides instructions for maintaining the highly available web application deployment on Azure Kubernetes Service (AKS).

## Table of Contents

1. [Routine Maintenance Tasks](#routine-maintenance-tasks)
2. [Scaling the Solution](#scaling-the-solution)
3. [Updating Components](#updating-components)
4. [Backup and Restore](#backup-and-restore)
5. [Monitoring and Alerting](#monitoring-and-alerting)
6. [Troubleshooting](#troubleshooting)
7. [Security Maintenance](#security-maintenance)

## Routine Maintenance Tasks

### Daily Tasks

1. **Health Checks**:
   ```bash
   ./deployment_scripts/monitor.sh
   ```

2. **Log Review**:
   - Review application logs in Log Analytics
   - Check for error patterns or unusual activity
   - Verify successful database replication

### Weekly Tasks

1. **Update Container Images**:
   - Pull latest base images
   - Rebuild application containers with security patches
   - Deploy updated images using the update script

2. **Resource Utilization Review**:
   - Check CPU, memory, and storage utilization
   - Review autoscaling events
   - Optimize resource allocation if needed

### Monthly Tasks

1. **Security Updates**:
   - Apply Kubernetes version updates
   - Update node images
   - Rotate secrets and credentials

2. **Performance Testing**:
   - Conduct load tests
   - Verify failover mechanisms
   - Test disaster recovery procedures

## Scaling the Solution

### Horizontal Scaling

To scale the number of application pods:

```bash
# Scale web application in East US
kubectl scale deployment webapp -n webapp --replicas=10

# Scale web application in West US
KUBECONFIG=./west-kubeconfig kubectl scale deployment webapp -n webapp --replicas=10
```

### Vertical Scaling

To change the node VM size:

1. Update the Terraform variables in `infrastructure_code/variables.tf`
2. Apply the changes:
   ```bash
   cd infrastructure_code
   terraform apply
   ```

### Adding a New Region

To add a third region for additional redundancy:

1. Modify the Terraform configuration to include the new region
2. Apply the changes with Terraform
3. Deploy Kubernetes manifests to the new cluster
4. Update Front Door to include the new region

## Updating Components

### Kubernetes Version Update

1. Update the Kubernetes version in `infrastructure_code/variables.tf`
2. Apply the changes:
   ```bash
   cd infrastructure_code
   terraform apply
   ```

### Application Updates

Use the update script to deploy new application versions:

```bash
./deployment_scripts/update.sh webapp 2.0.0
```

### Database Schema Updates

For database schema updates:

1. Create a migration plan with backward compatibility
2. Apply migrations to the secondary region first
3. Test functionality in the secondary region
4. Apply migrations to the primary region
5. Verify replication and functionality

## Backup and Restore

### Database Backups

Azure SQL Database automatically creates full backups weekly, differential backups daily, and transaction log backups every 5-10 minutes.

To create a manual backup:

```bash
az sql db export --resource-group rg-aks-ha-eastus --server sql-aks-ha-eastus --name sqldb-aks-ha-eastus --admin-user sqladmin --admin-password "P@ssw0rd1234!" --storage-key-type StorageAccessKey --storage-key <storage-key> --storage-uri <storage-uri>
```

### Application State Backups

For application state stored in Kubernetes:

```bash
# Backup Kubernetes resources
kubectl get all -A -o yaml > k8s_backup.yaml

# Backup ConfigMaps and Secrets
kubectl get configmaps,secrets -A -o yaml > k8s_config_backup.yaml
```

### Restore Procedures

To restore from backups:

1. **Database Restore**:
   ```bash
   az sql db import --resource-group rg-aks-ha-eastus --server sql-aks-ha-eastus --name sqldb-aks-ha-eastus --admin-user sqladmin --admin-password "P@ssw0rd1234!" --storage-key-type StorageAccessKey --storage-key <storage-key> --storage-uri <storage-uri>
   ```

2. **Application State Restore**:
   ```bash
   kubectl apply -f k8s_backup.yaml
   ```

## Monitoring and Alerting

### Setting Up Alerts

Create alerts for critical metrics:

```bash
# CPU usage alert
az monitor metrics alert create \
  --name "High CPU Alert" \
  --resource-group rg-aks-ha-eastus \
  --scopes <aks-cluster-resource-id> \
  --condition "avg Percentage CPU > 80" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action <action-group-id>

# Pod restart alert
az monitor metrics alert create \
  --name "Pod Restart Alert" \
  --resource-group rg-aks-ha-eastus \
  --scopes <aks-cluster-resource-id> \
  --condition "count PodRestart > 5" \
  --window-size 5m \
  --evaluation-frequency 1m \
  --action <action-group-id>
```

### Log Queries

Useful Log Analytics queries for monitoring:

```kusto
// Error rate by container
ContainerLog
| where TimeGenerated > ago(1h)
| where LogEntry contains "error" or LogEntry contains "exception"
| summarize ErrorCount=count() by ContainerName, bin(TimeGenerated, 5m)
| render timechart

// Pod restarts
KubePodInventory
| where TimeGenerated > ago(1d)
| where Namespace in ("webapp", "database")
| summarize RestartCount=sum(PodRestartCount) by Name, bin(TimeGenerated, 1h)
| render timechart
```

## Troubleshooting

### Common Issues and Resolutions

#### Pod Scheduling Issues

**Symptoms**: Pods stuck in Pending state

**Resolution**:
```bash
# Check node capacity
kubectl describe nodes | grep -A 5 "Allocated resources"

# Check pod events
kubectl describe pod <pod-name> -n <namespace>

# Scale up node pool if needed
az aks nodepool scale --resource-group rg-aks-ha-eastus --cluster-name aks-webapp-eastus --name webapppool --node-count 6
```

#### Database Connection Issues

**Symptoms**: Application logs show database connection errors

**Resolution**:
```bash
# Check database service
kubectl get service database -n database

# Verify database pods are running
kubectl get pods -n database

# Check database logs
kubectl logs -l app=database -n database

# Verify SQL failover group status
az sql failover-group show --name fog-aks-ha-sql --server sql-aks-ha-eastus --resource-group rg-aks-ha-eastus
```

#### Ingress Issues

**Symptoms**: Unable to access application through Front Door

**Resolution**:
```bash
# Check ingress status
kubectl get ingress -A

# Verify Application Gateway health
az network application-gateway show-health --resource-group rg-aks-ha-eastus --name appgw-aks-eastus

# Check Front Door routing
az network front-door probe show --front-door-name fd-aks-ha-webapp --resource-group rg-aks-ha-eastus --name DefaultProbeSettings
```

## Security Maintenance

### Secret Rotation

Rotate secrets regularly:

```bash
# Generate new secrets
NEW_DB_PASSWORD=$(openssl rand -base64 16)
NEW_DB_PASSWORD_BASE64=$(echo -n "$NEW_DB_PASSWORD" | base64)

# Update Kubernetes secrets
kubectl patch secret webapp-secrets -n webapp --type='json' -p='[{"op": "replace", "path": "/data/db_password", "value": "'$NEW_DB_PASSWORD_BASE64'"}]'
kubectl patch secret database-secrets -n database --type='json' -p='[{"op": "replace", "path": "/data/db_password", "value": "'$NEW_DB_PASSWORD_BASE64'"}]'

# Update SQL Database password
az sql server update --resource-group rg-aks-ha-eastus --name sql-aks-ha-eastus --admin-password "$NEW_DB_PASSWORD"
az sql server update --resource-group rg-aks-ha-westus --name sql-aks-ha-westus --admin-password "$NEW_DB_PASSWORD"
```

### Certificate Renewal

For TLS certificates:

```bash
# Check certificate expiration
kubectl get secret webapp-tls-secret -n webapp -o jsonpath='{.metadata.annotations.cert-manager\.io/certificate-expiry}'

# Renew certificate (if using cert-manager)
kubectl annotate certificate webapp-cert -n webapp cert-manager.io/renew="true"
```

### Security Scanning

Run regular security scans:

```bash
# Scan container images
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image ${ACR_LOGIN_SERVER}/webapp:latest

# Scan Kubernetes resources
kubectl run trivy --rm -i --tty --image aquasec/trivy:latest -- k8s --report summary -n webapp
```

This maintenance guide provides comprehensive instructions for maintaining the highly available AKS solution. Regular maintenance is essential to ensure the continued reliability, security, and performance of the application.

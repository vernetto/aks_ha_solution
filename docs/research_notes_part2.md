# Azure AKS High Availability Research Notes - Part 2

## Active-Active High Availability Solution

### Overview
- Deploy two independent and identical AKS clusters in two paired Azure regions
- Both clusters actively serve traffic
- Use global traffic manager (Azure Front Door) to distribute traffic across clusters
- Consistently configure clusters to host identical applications

### Key Components
1. **Multiple Clusters and Regions**
   - Deploy AKS clusters in separate Azure regions
   - Azure Front Door routes traffic between regions
   - If one region becomes unavailable, traffic routes to available regions

2. **Hub-Spoke Network Per Region**
   - Regional hub-spoke network pair for each AKS instance
   - Azure Firewall Manager policies manage firewall rules across regions

3. **Regional Key Store**
   - Azure Key Vault in each region for sensitive values and keys
   - Support services specific to each region

4. **Azure Front Door**
   - Load balances and routes traffic to regional Azure Application Gateway instances
   - Provides layer seven global routing

5. **Log Analytics**
   - Regional Log Analytics instances store regional networking metrics and logs
   - Shared instance stores metrics and logs for all AKS instances

6. **Container Registry**
   - Single Azure Container Registry instance for all Kubernetes clusters
   - Geo-replication enables image replication to selected Azure regions
   - Provides continued access to images even during regional outages

### Availability Zones
- Distribute cluster nodes across multiple isolated locations within an Azure region
- Protects against zone-level failures (power outage, hardware failure, network issues)
- Improves performance and scalability by reducing latency and contention
- Specify zone numbers when creating or updating node pools

### Failure Points and Mitigation

#### Application Pods (Regional)
- Kubernetes deployment creates multiple replicas (ReplicaSet)
- If one pod is unavailable, traffic routes to remaining replicas
- ReplicaSet maintains specified number of replicas
- Liveness probes check application state and force recreation if unresponsive

#### Application Pods (Global)
- When a region becomes unavailable, Azure Front Door routes traffic to healthy regions
- Considerations for handling increased traffic:
  - Right-size network and compute resources
  - Use Horizontal Pod Autoscaler to increase pod replicas
  - Use Cluster Autoscaler to increase node counts

#### Kubernetes Node Pools (Regional)
- Use Azure Availability Zones to protect against localized failures
- Ensures physical separation of nodes across availability zones

#### Kubernetes Node Pools (Global)
- During complete regional failure, traffic routes to healthy regions
- Compensate for increased traffic with proper scaling

### Failover Testing
- Azure Chaos Studio offers ability to create chaos experiments on clusters

## Database High Availability Considerations

For stateful applications requiring database integration:

1. **Azure SQL Database**
   - Auto-failover groups for geo-replication
   - Active geo-replication for read replicas
   - Business continuity with automatic failover

2. **Azure Cosmos DB**
   - Global distribution with multi-region writes
   - Automatic regional failover
   - 99.999% availability SLA

3. **Azure Database for MySQL/PostgreSQL**
   - Geo-redundant backups
   - Read replicas across regions

## Networking Considerations

1. **Azure Load Balancer**
   - Standard SKU for zone redundancy
   - Health probes for service monitoring

2. **Azure Application Gateway**
   - Web Application Firewall (WAF) protection
   - SSL termination
   - Cookie-based session affinity

3. **Network Security**
   - Network Security Groups (NSGs)
   - Azure Firewall for advanced protection
   - Private endpoints for PaaS services

## Monitoring and Observability

1. **Azure Monitor**
   - Container insights for AKS monitoring
   - Log Analytics for centralized logging
   - Application Insights for application performance monitoring

2. **Prometheus and Grafana**
   - Open-source monitoring solutions
   - Rich visualization capabilities
   - Pre-built dashboards for Kubernetes

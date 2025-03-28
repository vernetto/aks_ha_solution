# Azure AKS High Availability Research Notes

## Four HA Pillars for AKS Applications

1. **Redundancy**
   - Kubernetes controller type (Deployment, StatefulSet)
   - Number of replicas (multiple replicas for high-volume components)
   - Scheduling anti-affinity (pods distributed across availability zones)
   - Horizontal Pod Autoscaling (HPA) for automatic scaling based on resource utilization

2. **Monitoring**
   - Liveness probes (monitor pod health, restart containers on failure)
   - Readiness probes (determine if pod should receive traffic)
   - Startup probes (prevent false positives for slow-starting applications)

3. **Recovery**
   - Service type (load balancing, DNS entries automatically update)
   - Leader election (for singleton components)
   - Restart policy (automatic container restart)
   - Pre-stop hooks (graceful termination)

4. **Checkpointing**
   - Persistent volume claims (PVCs)
   - Persistent volumes (PVs)

## Node and Pod Structure

- AKS clusters can have multiple node pools with different VM sizes and specifications
- Node pools can be spread across multiple availability zones for high availability
- Specialized node pools can be created for specific workloads:
  - Database pods on nodes with fast SSDs
  - Machine learning pods on nodes with GPUs
  - General-purpose nodes for web application components

## Identifying Single Points of Failure

- Critical path components must be replicated
- Even replicated components are considered single points of failure if not monitored
- All tiers of the application need redundancy (business logic tier, data tier)

## Eliminating Single Points of Failure

- Deploy applications to replicate critical path components
- Employ load balancers for traffic distribution
- Implement monitoring for health checks
- Set up recovery mechanisms for automatic healing
- Use persistent storage for stateful components

## Key Configurations for High Availability

### Redundancy
- Use Deployment controller (`kind: Deployment`) for most components
- Use StatefulSet controller for components that need stable identity
- Set appropriate number of replicas (`spec.replicas`) based on workload
- Configure resource requests and limits (`spec.containers[].resources`)
- Implement pod anti-affinity (`spec.affinity.podAntiAffinity`) to distribute across zones

### Monitoring
- Configure liveness probes (`spec.containers.livenessProbe`)
- Set up readiness probes (`spec.containers.readinessProbe`)
- Implement startup probes (`spec.containers.startupProbe`) for slow-starting applications

### Recovery
- Expose pods through Kubernetes services (`spec.type`)
- Implement leader election for singleton components
- Configure restart policy for automatic recovery
- Set up pre-stop hooks for graceful termination

### Checkpointing
- Use persistent volume claims for stateful components
- Configure appropriate storage classes for persistent volumes

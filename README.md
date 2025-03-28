# Azure AKS High Availability Solution - README

This repository contains a complete solution for deploying a highly available web application in Azure Kubernetes Service (AKS) with load balancing and database integration.

## Solution Overview

The solution implements an active-active high availability model with:

- Two identical AKS clusters deployed in paired Azure regions (East US and West US)
- Both clusters actively serving traffic
- Global traffic distribution via Azure Front Door
- Regional failover capabilities
- Hub-spoke network topology
- Zone-redundant resources within each region

## Repository Structure

```
aks_ha_solution/
├── diagrams/                  # Architecture diagrams
├── docs/                      # Documentation
├── infrastructure_code/       # Terraform templates
├── k8s_manifests/             # Kubernetes manifests
└── deployment_scripts/        # Deployment and management scripts
```

## Documentation

- [Architecture Documentation](docs/documentation.md) - Comprehensive overview of the solution architecture
- [Deployment Guide](docs/deployment_guide.md) - Step-by-step instructions for deploying the solution
- [Maintenance Guide](docs/maintenance_guide.md) - Instructions for maintaining and operating the solution

## Prerequisites

- Azure subscription with sufficient permissions
- Azure CLI installed and configured
- Terraform installed (version 1.0 or later)
- kubectl installed
- Docker installed (for building and pushing container images)

## Quick Start

1. Clone this repository
2. Make the deployment scripts executable:
   ```bash
   chmod +x deployment_scripts/*.sh
   ```
3. Run the deployment script:
   ```bash
   ./deployment_scripts/deploy.sh
   ```

## Features

- **High Availability**: Multi-region, multi-zone deployment with automatic failover
- **Scalability**: Horizontal and vertical scaling capabilities
- **Security**: Network security, Azure AD integration, and secrets management
- **Monitoring**: Comprehensive monitoring and alerting
- **Disaster Recovery**: Automatic failover and recovery mechanisms
- **Automation**: Infrastructure as code and deployment automation

## License

This solution is provided as-is with no warranties or guarantees.

## Contact

For questions or support, please contact your Azure representative.

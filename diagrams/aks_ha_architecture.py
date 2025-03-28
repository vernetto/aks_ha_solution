#!/usr/bin/env python3
from diagrams import Diagram, Cluster, Edge
from diagrams.azure.compute import AKS, VMScaleSet
from diagrams.azure.network import ApplicationGateway, LoadBalancers, VirtualNetworks, Firewall
from diagrams.azure.web import FrontDoors
from diagrams.azure.database import SQLDatabase, CosmosDB
from diagrams.azure.storage import StorageAccounts
from diagrams.azure.security import KeyVault
from diagrams.azure.analytics import LogAnalyticsWorkspaces
from diagrams.azure.identity import ActiveDirectory
from diagrams.azure.integration import APIManagement
from diagrams.k8s.compute import Pod, Deployment, StatefulSet
from diagrams.k8s.network import Service, Ingress
from diagrams.k8s.storage import PV, PVC
from diagrams.onprem.monitoring import Prometheus, Grafana

# Set diagram attributes
graph_attr = {
    "fontsize": "30",
    "bgcolor": "white",
    "margin": "0",
    "pad": "0.5"
}

# Create the main diagram
with Diagram("Azure AKS High Availability Architecture", show=False, filename="aks_ha_architecture", outformat="png", graph_attr=graph_attr):
    
    # Global services
    aad = ActiveDirectory("Azure AD")
    frontdoor = FrontDoors("Azure Front Door")
    
    # Create regions
    with Cluster("Region 1 (East US)"):
        # Network components
        with Cluster("Hub VNet"):
            hub_vnet1 = VirtualNetworks("Hub VNet")
            firewall1 = Firewall("Azure Firewall")
        
        with Cluster("Spoke VNet"):
            spoke_vnet1 = VirtualNetworks("Spoke VNet")
            appgw1 = ApplicationGateway("App Gateway + WAF")
        
        # AKS Cluster
        with Cluster("AKS Cluster 1"):
            aks1 = AKS("AKS Control Plane")
            
            with Cluster("System Node Pool"):
                system_nodes1 = VMScaleSet("System Nodes")
            
            with Cluster("Web App Node Pool"):
                webapp_nodes1 = VMScaleSet("Web App Nodes")
                
                with Cluster("Web Application"):
                    web_deploy1 = Deployment("Web Deployment")
                    web_pods1 = [Pod("Web Pod 1"), Pod("Web Pod 2"), Pod("Web Pod 3")]
                    web_service1 = Service("Web Service")
                    ingress1 = Ingress("Ingress Controller")
                    
                    for pod in web_pods1:
                        web_deploy1 >> pod
                        pod >> web_service1
                    
                    web_service1 >> ingress1
            
            with Cluster("Database Node Pool"):
                db_nodes1 = VMScaleSet("DB Nodes")
                
                with Cluster("Database"):
                    db_stateful1 = StatefulSet("DB StatefulSet")
                    db_pods1 = [Pod("DB Pod 1"), Pod("DB Pod 2"), Pod("DB Pod 3")]
                    db_service1 = Service("DB Service")
                    db_pvc1 = PVC("Persistent Volume Claim")
                    db_pv1 = PV("Persistent Volume")
                    
                    for pod in db_pods1:
                        db_stateful1 >> pod
                        pod >> db_service1
                    
                    db_pods1[0] - db_pvc1
                    db_pvc1 - db_pv1
        
        # Azure services
        sql1 = SQLDatabase("Azure SQL")
        cosmos1 = CosmosDB("Cosmos DB")
        storage1 = StorageAccounts("Storage Account")
        keyvault1 = KeyVault("Key Vault")
        logs1 = LogAnalyticsWorkspaces("Log Analytics")
        
        # Monitoring
        with Cluster("Monitoring"):
            prometheus1 = Prometheus("Prometheus")
            grafana1 = Grafana("Grafana")
            
            prometheus1 >> grafana1
    
    # Region 2
    with Cluster("Region 2 (West US)"):
        # Network components
        with Cluster("Hub VNet"):
            hub_vnet2 = VirtualNetworks("Hub VNet")
            firewall2 = Firewall("Azure Firewall")
        
        with Cluster("Spoke VNet"):
            spoke_vnet2 = VirtualNetworks("Spoke VNet")
            appgw2 = ApplicationGateway("App Gateway + WAF")
        
        # AKS Cluster
        with Cluster("AKS Cluster 2"):
            aks2 = AKS("AKS Control Plane")
            
            with Cluster("System Node Pool"):
                system_nodes2 = VMScaleSet("System Nodes")
            
            with Cluster("Web App Node Pool"):
                webapp_nodes2 = VMScaleSet("Web App Nodes")
                
                with Cluster("Web Application"):
                    web_deploy2 = Deployment("Web Deployment")
                    web_pods2 = [Pod("Web Pod 1"), Pod("Web Pod 2"), Pod("Web Pod 3")]
                    web_service2 = Service("Web Service")
                    ingress2 = Ingress("Ingress Controller")
                    
                    for pod in web_pods2:
                        web_deploy2 >> pod
                        pod >> web_service2
                    
                    web_service2 >> ingress2
            
            with Cluster("Database Node Pool"):
                db_nodes2 = VMScaleSet("DB Nodes")
                
                with Cluster("Database"):
                    db_stateful2 = StatefulSet("DB StatefulSet")
                    db_pods2 = [Pod("DB Pod 1"), Pod("DB Pod 2"), Pod("DB Pod 3")]
                    db_service2 = Service("DB Service")
                    db_pvc2 = PVC("Persistent Volume Claim")
                    db_pv2 = PV("Persistent Volume")
                    
                    for pod in db_pods2:
                        db_stateful2 >> pod
                        pod >> db_service2
                    
                    db_pods2[0] - db_pvc2
                    db_pvc2 - db_pv2
        
        # Azure services
        sql2 = SQLDatabase("Azure SQL")
        cosmos2 = CosmosDB("Cosmos DB")
        storage2 = StorageAccounts("Storage Account")
        keyvault2 = KeyVault("Key Vault")
        logs2 = LogAnalyticsWorkspaces("Log Analytics")
        
        # Monitoring
        with Cluster("Monitoring"):
            prometheus2 = Prometheus("Prometheus")
            grafana2 = Grafana("Grafana")
            
            prometheus2 >> grafana2
    
    # Connect components
    frontdoor >> appgw1
    frontdoor >> appgw2
    
    appgw1 >> ingress1
    appgw2 >> ingress2
    
    # Database replication
    sql1 << Edge(label="Geo-Replication") >> sql2
    cosmos1 << Edge(label="Multi-Region Write") >> cosmos2
    
    # Authentication
    aad >> aks1
    aad >> aks2
    
    # Network connections
    hub_vnet1 << Edge(label="Peering") >> spoke_vnet1
    hub_vnet2 << Edge(label="Peering") >> spoke_vnet2
    
    # Firewall connections
    firewall1 >> spoke_vnet1
    firewall2 >> spoke_vnet2

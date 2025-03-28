provider "azurerm" {
  features {}
}

# Resource Group for East US Region
resource "azurerm_resource_group" "east" {
  name     = "rg-aks-ha-eastus"
  location = "eastus"
  tags = {
    environment = "production"
    application = "webapp"
  }
}

# Resource Group for West US Region
resource "azurerm_resource_group" "west" {
  name     = "rg-aks-ha-westus"
  location = "westus"
  tags = {
    environment = "production"
    application = "webapp"
  }
}

# Log Analytics Workspace (Shared)
resource "azurerm_log_analytics_workspace" "shared" {
  name                = "log-aks-ha-shared"
  location            = azurerm_resource_group.east.location
  resource_group_name = azurerm_resource_group.east.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags = {
    environment = "production"
    application = "webapp"
  }
}

# Container Registry (Shared)
resource "azurerm_container_registry" "acr" {
  name                = "acrakshawebapp"
  resource_group_name = azurerm_resource_group.east.name
  location            = azurerm_resource_group.east.location
  sku                 = "Premium"
  admin_enabled       = false
  georeplications {
    location                = azurerm_resource_group.west.location
    zone_redundancy_enabled = true
  }
  tags = {
    environment = "production"
    application = "webapp"
  }
}

# Key Vault East US
resource "azurerm_key_vault" "east" {
  name                        = "kv-aks-ha-eastus"
  location                    = azurerm_resource_group.east.location
  resource_group_name         = azurerm_resource_group.east.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"
  tags = {
    environment = "production"
    application = "webapp"
  }
}

# Key Vault West US
resource "azurerm_key_vault" "west" {
  name                        = "kv-aks-ha-westus"
  location                    = azurerm_resource_group.west.location
  resource_group_name         = azurerm_resource_group.west.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"
  tags = {
    environment = "production"
    application = "webapp"
  }
}

# Get current client configuration
data "azurerm_client_config" "current" {}

# Virtual Network for East US Hub
resource "azurerm_virtual_network" "hub_east" {
  name                = "vnet-hub-eastus"
  location            = azurerm_resource_group.east.location
  resource_group_name = azurerm_resource_group.east.name
  address_space       = ["10.0.0.0/16"]
  tags = {
    environment = "production"
    application = "webapp"
  }
}

# Virtual Network for East US Spoke
resource "azurerm_virtual_network" "spoke_east" {
  name                = "vnet-spoke-eastus"
  location            = azurerm_resource_group.east.location
  resource_group_name = azurerm_resource_group.east.name
  address_space       = ["10.1.0.0/16"]
  tags = {
    environment = "production"
    application = "webapp"
  }
}

# Virtual Network for West US Hub
resource "azurerm_virtual_network" "hub_west" {
  name                = "vnet-hub-westus"
  location            = azurerm_resource_group.west.location
  resource_group_name = azurerm_resource_group.west.name
  address_space       = ["10.2.0.0/16"]
  tags = {
    environment = "production"
    application = "webapp"
  }
}

# Virtual Network for West US Spoke
resource "azurerm_virtual_network" "spoke_west" {
  name                = "vnet-spoke-westus"
  location            = azurerm_resource_group.west.location
  resource_group_name = azurerm_resource_group.west.name
  address_space       = ["10.3.0.0/16"]
  tags = {
    environment = "production"
    application = "webapp"
  }
}

# Subnet for AKS in East US
resource "azurerm_subnet" "aks_east" {
  name                 = "snet-aks-eastus"
  resource_group_name  = azurerm_resource_group.east.name
  virtual_network_name = azurerm_virtual_network.spoke_east.name
  address_prefixes     = ["10.1.0.0/20"]
}

# Subnet for Application Gateway in East US
resource "azurerm_subnet" "appgw_east" {
  name                 = "snet-appgw-eastus"
  resource_group_name  = azurerm_resource_group.east.name
  virtual_network_name = azurerm_virtual_network.spoke_east.name
  address_prefixes     = ["10.1.16.0/24"]
}

# Subnet for AKS in West US
resource "azurerm_subnet" "aks_west" {
  name                 = "snet-aks-westus"
  resource_group_name  = azurerm_resource_group.west.name
  virtual_network_name = azurerm_virtual_network.spoke_west.name
  address_prefixes     = ["10.3.0.0/20"]
}

# Subnet for Application Gateway in West US
resource "azurerm_subnet" "appgw_west" {
  name                 = "snet-appgw-westus"
  resource_group_name  = azurerm_resource_group.west.name
  virtual_network_name = azurerm_virtual_network.spoke_west.name
  address_prefixes     = ["10.3.16.0/24"]
}

# Virtual Network Peering East Hub to Spoke
resource "azurerm_virtual_network_peering" "east_hub_to_spoke" {
  name                      = "peer-hub-to-spoke-eastus"
  resource_group_name       = azurerm_resource_group.east.name
  virtual_network_name      = azurerm_virtual_network.hub_east.name
  remote_virtual_network_id = azurerm_virtual_network.spoke_east.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
}

# Virtual Network Peering East Spoke to Hub
resource "azurerm_virtual_network_peering" "east_spoke_to_hub" {
  name                      = "peer-spoke-to-hub-eastus"
  resource_group_name       = azurerm_resource_group.east.name
  virtual_network_name      = azurerm_virtual_network.spoke_east.name
  remote_virtual_network_id = azurerm_virtual_network.hub_east.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false
}

# Virtual Network Peering West Hub to Spoke
resource "azurerm_virtual_network_peering" "west_hub_to_spoke" {
  name                      = "peer-hub-to-spoke-westus"
  resource_group_name       = azurerm_resource_group.west.name
  virtual_network_name      = azurerm_virtual_network.hub_west.name
  remote_virtual_network_id = azurerm_virtual_network.spoke_west.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  allow_gateway_transit        = true
}

# Virtual Network Peering West Spoke to Hub
resource "azurerm_virtual_network_peering" "west_spoke_to_hub" {
  name                      = "peer-spoke-to-hub-westus"
  resource_group_name       = azurerm_resource_group.west.name
  virtual_network_name      = azurerm_virtual_network.spoke_west.name
  remote_virtual_network_id = azurerm_virtual_network.hub_west.id
  allow_virtual_network_access = true
  allow_forwarded_traffic      = true
  use_remote_gateways          = false
}

# AKS Cluster in East US
resource "azurerm_kubernetes_cluster" "east" {
  name                = "aks-webapp-eastus"
  location            = azurerm_resource_group.east.location
  resource_group_name = azurerm_resource_group.east.name
  dns_prefix          = "aks-webapp-eastus"
  kubernetes_version  = "1.27.7"
  sku_tier            = "Standard"

  default_node_pool {
    name                = "systempool"
    vm_size             = "Standard_D4s_v3"
    availability_zones  = [1, 2, 3]
    enable_auto_scaling = true
    min_count           = 3
    max_count           = 5
    vnet_subnet_id      = azurerm_subnet.aks_east.id
    node_labels = {
      "nodepool-type" = "system"
      "environment"   = "production"
    }
    tags = {
      environment = "production"
      application = "webapp"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "calico"
    load_balancer_sku  = "standard"
    service_cidr       = "10.0.0.0/16"
    dns_service_ip     = "10.0.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
  }

  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.shared.id
    }
  }

  tags = {
    environment = "production"
    application = "webapp"
  }
}

# AKS Cluster in West US
resource "azurerm_kubernetes_cluster" "west" {
  name                = "aks-webapp-westus"
  location            = azurerm_resource_group.west.location
  resource_group_name = azurerm_resource_group.west.name
  dns_prefix          = "aks-webapp-westus"
  kubernetes_version  = "1.27.7"
  sku_tier            = "Standard"

  default_node_pool {
    name                = "systempool"
    vm_size             = "Standard_D4s_v3"
    availability_zones  = [1, 2, 3]
    enable_auto_scaling = true
    min_count           = 3
    max_count           = 5
    vnet_subnet_id      = azurerm_subnet.aks_west.id
    node_labels = {
      "nodepool-type" = "system"
      "environment"   = "production"
    }
    tags = {
      environment = "production"
      application = "webapp"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin     = "azure"
    network_policy     = "calico"
    load_balancer_sku  = "standard"
    service_cidr       = "10.0.0.0/16"
    dns_service_ip     = "10.0.0.10"
    docker_bridge_cidr = "172.17.0.1/16"
  }

  addon_profile {
    oms_agent {
      enabled                    = true
      log_analytics_workspace_id = azurerm_log_analytics_workspace.shared.id
    }
  }

  tags = {
    environment = "production"
    application = "webapp"
  }
}

# Web Application Node Pool for East US
resource "azurerm_kubernetes_cluster_node_pool" "webapp_east" {
  name                  = "webapppool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.east.id
  vm_size               = "Standard_D8s_v3"
  availability_zones    = [1, 2, 3]
  enable_auto_scaling   = true
  min_count             = 3
  max_count             = 9
  vnet_subnet_id        = azurerm_subnet.aks_east.id
  node_labels = {
    "nodepool-type" = "webapp"
    "environment"   = "production"
  }
  tags = {
    environment = "production"
    application = "webapp"
  }
}

# Database Node Pool for East US
resource "azurerm_kubernetes_cluster_node_pool" "db_east" {
  name                  = "dbpool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.east.id
  vm_size               = "Standard_E8s_v3"
  availability_zones    = [1, 2, 3]
  enable_auto_scaling   = true
  min_count             = 3
  max_count             = 5
  vnet_subnet_id        = azurerm_subnet.aks_east.id
  node_labels = {
    "nodepool-type" = "database"
    "environment"   = "production"
  }
  node_taints = [
    "dedicated=database:NoSchedule"
  ]
  tags = {
    environment = "production"
    application = "webapp"
  }
}

# Web Application Node Pool for West US
resource "azurerm_kubernetes_cluster_node_pool" "webapp_west" {
  name                  = "webapppool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.west.id
  vm_size               = "Standard_D8s_v3"
  availability_zones    = [1, 2, 3]
  enable_auto_scaling   = true
  min_count             = 3
  max_count             = 9
  vnet_subnet_id        = azurerm_subnet.aks_west.id
  node_labels = {
    "nodepool-type" = "webapp"
    "environment"   = "production"
  }
  tags = {
    environment = "production"
    application = "webapp"
  }
}

# Database Node Pool for West US
resource "azurerm_kubernetes_cluster_node_pool" "db_west" {
  name                  = "dbpool"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.west.id
  vm_size               = "Standard_E8s_v3"
  availability_zones    = [1, 2, 3]
  enable_auto_scaling   = true
  min_count             = 3
  max_count             = 5
  vnet_subnet_id        = azurerm_subnet.aks_west.id
  node_labels = {
    "nodepool-type" = "database"
    "environment"   = "production"
  }
  node_taints = [
    "dedicated=database:NoSchedule"
  ]
  tags = {
    environment = "production"
    application = "webapp"
  }
}

# Public IP for Application Gateway in East US
resource "azurerm_public_ip" "appgw_east" {
  name                = "pip-appgw-eastus"
  resource_group_name = azurerm_resource_group.east.name
  location            = azurerm_resource_group.east.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [1, 2, 3]
  tags = {
    environment = "production"
    application = "webapp"
  }
}

# Public IP for Application Gateway in West US
resource "azurerm_public_ip" "appgw_west" {
  name                = "pip-appgw-westus"
  resource_group_name = azurerm_resource_group.west.name
  location            = azurerm_resource_group.west.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = [1, 2, 3]
  tags = {
    environment = "production"
    application = "webapp"
  }
}

# Application Gateway in East US
resource "azurerm_application_gateway" "east" {
  name                = "appgw-aks-eastus"
  resource_group_name = azurerm_resource_group.east.name
  location            = azurerm_resource_group.east.location
  zones               = [1, 2, 3]

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "gateway-ip-configuration"
    subnet_id = azurerm_subnet.appgw_east.id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_port {
    name = "https-port"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "frontend-ip-configuration"
    public_ip_address_id = azurerm_public_ip.appgw_east.id
  }

  backend_address_pool {
    name = "backend-pool"
  }

  backend_http_settings {
    name                  = "http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip-configuration"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "backend-pool"
    backend_http_settings_name = "http-settings"
    priority                   = 100
  }

  waf_configuration {
    enabled                  = true
    firewall_mode            = "Prevention"
    rule_set_type            = "OWASP"
    rule_set_version         = "3.2"
    file_upload_limit_mb     = 100
    request_body_check       = true
    max_request_body_size_kb = 128
  }

  tags = {
    environment = "production"
    application = "webapp"
  }
}

# Application Gateway in West US
resource "azurerm_application_gateway" "west" {
  name                = "appgw-aks-westus"
  resource_group_name = azurerm_resource_group.west.name
  location            = azurerm_resource_group.west.location
  zones               = [1, 2, 3]

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "gateway-ip-configuration"
    subnet_id = azurerm_subnet.appgw_west.id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_port {
    name = "https-port"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "frontend-ip-configuration"
    public_ip_address_id = azurerm_public_ip.appgw_west.id
  }

  backend_address_pool {
    name = "backend-pool"
  }

  backend_http_settings {
    name                  = "http-settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
  }

  http_listener {
    name                           = "http-listener"
    frontend_ip_configuration_name = "frontend-ip-configuration"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = "routing-rule"
    rule_type                  = "Basic"
    http_listener_name         = "http-listener"
    backend_address_pool_name  = "backend-pool"
    backend_http_settings_name = "http-settings"
    priority                   = 100
  }

  waf_configuration {
    enabled                  = true
    firewall_mode            = "Prevention"
    rule_set_type            = "OWASP"
    rule_set_version         = "3.2"
    file_upload_limit_mb     = 100
    request_body_check       = true
    max_request_body_size_kb = 128
  }

  tags = {
    environment = "production"
    application = "webapp"
  }
}

# Front Door Profile
resource "azurerm_frontdoor" "main" {
  name                = "fd-aks-ha-webapp"
  resource_group_name = azurerm_resource_group.east.name

  routing_rule {
    name               = "routing-rule"
    accepted_protocols = ["Http", "Https"]
    patterns_to_match  = ["/*"]
    frontend_endpoints = ["frontend-endpoint"]
    forwarding_configuration {
      forwarding_protocol = "HttpOnly"
      backend_pool_name   = "backend-pool"
    }
  }

  backend_pool_load_balancing {
    name = "load-balancing-settings"
  }

  backend_pool_health_probe {
    name = "health-probe"
  }

  backend_pool {
    name = "backend-pool"
    backend {
      host_header = azurerm_public_ip.appgw_east.ip_address
      address     = azurerm_public_ip.appgw_east.ip_address
      http_port   = 80
      https_port  = 443
      weight      = 50
      priority    = 1
    }
    backend {
      host_header = azurerm_public_ip.appgw_west.ip_address
      address     = azurerm_public_ip.appgw_west.ip_address
      http_port   = 80
      https_port  = 443
      weight      = 50
      priority    = 1
    }
    load_balancing_name = "load-balancing-settings"
    health_probe_name   = "health-probe"
  }

  frontend_endpoint {
    name      = "frontend-endpoint"
    host_name = "fd-aks-ha-webapp.azurefd.net"
  }

  tags = {
    environment = "production"
    application = "webapp"
  }
}

# Azure SQL Server in East US
resource "azurerm_mssql_server" "east" {
  name                         = "sql-aks-ha-eastus"
  resource_group_name          = azurerm_resource_group.east.name
  location                     = azurerm_resource_group.east.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "P@ssw0rd1234!"  # In production, use Key Vault or other secure method

  tags = {
    environment = "production"
    application = "webapp"
  }
}

# Azure SQL Server in West US
resource "azurerm_mssql_server" "west" {
  name                         = "sql-aks-ha-westus"
  resource_group_name          = azurerm_resource_group.west.name
  location                     = azurerm_resource_group.west.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "P@ssw0rd1234!"  # In production, use Key Vault or other secure method

  tags = {
    environment = "production"
    application = "webapp"
  }
}

# Azure SQL Database in East US
resource "azurerm_mssql_database" "east" {
  name                = "sqldb-aks-ha-eastus"
  server_id           = azurerm_mssql_server.east.id
  sku_name            = "BC_Gen5_2"
  zone_redundant      = true
  max_size_gb         = 100
  
  tags = {
    environment = "production"
    application = "webapp"
  }
}

# Azure SQL Failover Group
resource "azurerm_mssql_failover_group" "failover" {
  name                = "fog-aks-ha-sql"
  server_id           = azurerm_mssql_server.east.id
  databases           = [azurerm_mssql_database.east.id]
  partner_server {
    id = azurerm_mssql_server.west.id
  }
  
  read_write_endpoint_failover_policy {
    mode          = "Automatic"
    grace_minutes = 60
  }
  
  readonly_endpoint_failover_policy {
    mode = "Enabled"
  }
}

# Outputs
output "aks_east_id" {
  value = azurerm_kubernetes_cluster.east.id
}

output "aks_west_id" {
  value = azurerm_kubernetes_cluster.west.id
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
}

output "frontdoor_endpoint" {
  value = "https://${azurerm_frontdoor.main.frontend_endpoint[0].host_name}"
}

output "sql_failover_group_fqdn" {
  value = azurerm_mssql_failover_group.failover.listener_endpoint
}

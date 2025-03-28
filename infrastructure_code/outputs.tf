output "aks_east_id" {
  value = azurerm_kubernetes_cluster.east.id
  description = "The ID of the AKS cluster in East US region"
}

output "aks_west_id" {
  value = azurerm_kubernetes_cluster.west.id
  description = "The ID of the AKS cluster in West US region"
}

output "aks_east_kube_config" {
  value = azurerm_kubernetes_cluster.east.kube_config_raw
  sensitive = true
  description = "The kubeconfig for the East US AKS cluster"
}

output "aks_west_kube_config" {
  value = azurerm_kubernetes_cluster.west.kube_config_raw
  sensitive = true
  description = "The kubeconfig for the West US AKS cluster"
}

output "acr_login_server" {
  value = azurerm_container_registry.acr.login_server
  description = "The login server URL for the Azure Container Registry"
}

output "frontdoor_endpoint" {
  value = "https://${azurerm_frontdoor.main.frontend_endpoint[0].host_name}"
  description = "The Azure Front Door endpoint URL"
}

output "sql_failover_group_fqdn" {
  value = azurerm_mssql_failover_group.failover.listener_endpoint
  description = "The fully qualified domain name of the SQL failover group listener"
}

output "appgw_east_public_ip" {
  value = azurerm_public_ip.appgw_east.ip_address
  description = "The public IP address of the Application Gateway in East US"
}

output "appgw_west_public_ip" {
  value = azurerm_public_ip.appgw_west.ip_address
  description = "The public IP address of the Application Gateway in West US"
}

variable "resource_group_location_east" {
  type        = string
  default     = "eastus"
  description = "Location of the East US resource group."
}

variable "resource_group_location_west" {
  type        = string
  default     = "westus"
  description = "Location of the West US resource group."
}

variable "resource_group_name_prefix" {
  type        = string
  default     = "rg-aks-ha"
  description = "Prefix of the resource group name."
}

variable "kubernetes_version" {
  type        = string
  default     = "1.27.7"
  description = "Kubernetes version to use for the AKS clusters."
}

variable "system_node_count" {
  type        = number
  description = "The initial quantity of system nodes for the node pool."
  default     = 3
}

variable "webapp_node_count" {
  type        = number
  description = "The initial quantity of web application nodes for the node pool."
  default     = 3
}

variable "database_node_count" {
  type        = number
  description = "The initial quantity of database nodes for the node pool."
  default     = 3
}

variable "system_node_vm_size" {
  type        = string
  description = "The VM size for system nodes."
  default     = "Standard_D4s_v3"
}

variable "webapp_node_vm_size" {
  type        = string
  description = "The VM size for web application nodes."
  default     = "Standard_D8s_v3"
}

variable "database_node_vm_size" {
  type        = string
  description = "The VM size for database nodes."
  default     = "Standard_E8s_v3"
}

variable "admin_username" {
  type        = string
  description = "The admin username for SQL Server."
  default     = "sqladmin"
}

variable "admin_password" {
  type        = string
  description = "The admin password for SQL Server."
  default     = "P@ssw0rd1234!"
  sensitive   = true
}

variable "environment" {
  type        = string
  description = "Environment name (e.g., production, staging, development)."
  default     = "production"
}

variable "application_name" {
  type        = string
  description = "Application name."
  default     = "webapp"
}

variable "tags" {
  type        = map(string)
  description = "Tags to apply to all resources."
  default     = {
    environment = "production"
    application = "webapp"
  }
}

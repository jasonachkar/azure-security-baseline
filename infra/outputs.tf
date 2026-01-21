# =============================================================================
# OUTPUTS
# =============================================================================

output "resource_group_names" {
  description = "Names of created resource groups"
  value = {
    security = azurerm_resource_group.security.name
    network  = azurerm_resource_group.network.name
    workload = azurerm_resource_group.workload.name
  }
}

output "log_analytics_workspace" {
  description = "Log Analytics workspace details"
  value = {
    id           = azurerm_log_analytics_workspace.main.id
    name         = azurerm_log_analytics_workspace.main.name
    workspace_id = azurerm_log_analytics_workspace.main.workspace_id
  }
}

output "key_vault" {
  description = "Key Vault details"
  value = {
    id   = azurerm_key_vault.main.id
    name = azurerm_key_vault.main.name
    uri  = azurerm_key_vault.main.vault_uri
  }
}

output "virtual_networks" {
  description = "Virtual network details"
  value = {
    hub = {
      id   = azurerm_virtual_network.hub.id
      name = azurerm_virtual_network.hub.name
    }
    spoke = {
      id   = azurerm_virtual_network.spoke.id
      name = azurerm_virtual_network.spoke.name
    }
  }
}

output "subnets" {
  description = "Subnet details"
  value = {
    app = {
      id   = azurerm_subnet.app.id
      name = azurerm_subnet.app.name
    }
    data = {
      id   = azurerm_subnet.data.id
      name = azurerm_subnet.data.name
    }
    privateendpoint = {
      id   = azurerm_subnet.privateendpoint.id
      name = azurerm_subnet.privateendpoint.name
    }
  }
}

output "private_endpoints" {
  description = "Private endpoint details"
  value = {
    keyvault = {
      id                 = azurerm_private_endpoint.keyvault.id
      private_ip_address = azurerm_private_endpoint.keyvault.private_service_connection[0].private_ip_address
    }
  }
}

# =============================================================================
# SENSITIVE OUTPUTS (use with care)
# =============================================================================

output "tenant_id" {
  description = "Azure AD tenant ID"
  value       = data.azurerm_client_config.current.tenant_id
  sensitive   = true
}

output "subscription_id" {
  description = "Azure subscription ID"
  value       = data.azurerm_subscription.current.subscription_id
  sensitive   = true
}

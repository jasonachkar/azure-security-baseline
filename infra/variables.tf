# =============================================================================
# REQUIRED VARIABLES
# =============================================================================

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "canadacentral"
}

variable "project_name" {
  description = "Project name used in resource naming"
  type        = string
  default     = "secbaseline"
}

# =============================================================================
# NETWORK CONFIGURATION
# =============================================================================

variable "hub_vnet_address_space" {
  description = "Address space for hub VNET"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "spoke_vnet_address_space" {
  description = "Address space for spoke VNET"
  type        = list(string)
  default     = ["10.1.0.0/16"]
}

variable "subnet_config" {
  description = "Subnet configuration"
  type = map(object({
    address_prefix = string
    vnet           = string # "hub" or "spoke"
  }))
  default = {
    bastion = {
      address_prefix = "10.0.1.0/26"
      vnet           = "hub"
    }
    firewall = {
      address_prefix = "10.0.2.0/26"
      vnet           = "hub"
    }
    gateway = {
      address_prefix = "10.0.3.0/27"
      vnet           = "hub"
    }
    app = {
      address_prefix = "10.1.1.0/24"
      vnet           = "spoke"
    }
    data = {
      address_prefix = "10.1.2.0/24"
      vnet           = "spoke"
    }
    privateendpoint = {
      address_prefix = "10.1.3.0/24"
      vnet           = "spoke"
    }
  }
}

# =============================================================================
# KEY VAULT CONFIGURATION
# =============================================================================

variable "keyvault_sku" {
  description = "Key Vault SKU (standard or premium for HSM)"
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium"], var.keyvault_sku)
    error_message = "Key Vault SKU must be standard or premium."
  }
}

variable "keyvault_soft_delete_retention_days" {
  description = "Soft delete retention period in days"
  type        = number
  default     = 90
}

# =============================================================================
# LOG ANALYTICS CONFIGURATION
# =============================================================================

variable "log_analytics_retention_days" {
  description = "Log Analytics workspace retention in days"
  type        = number
  default     = 90
}

variable "log_analytics_sku" {
  description = "Log Analytics workspace SKU"
  type        = string
  default     = "PerGB2018"
}

# =============================================================================
# DEFENDER FOR CLOUD
# =============================================================================

variable "defender_plans" {
  description = "Defender for Cloud plans to enable"
  type        = list(string)
  default = [
    "VirtualMachines",
    "SqlServers",
    "AppServices",
    "StorageAccounts",
    "KeyVaults",
    "Containers"
  ]
}

# =============================================================================
# TAGS
# =============================================================================

variable "common_tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}

locals {
  # Merge provided tags with required tags
  tags = merge(
    var.common_tags,
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      Repository  = "azure-security-baseline"
    }
  )

  # Resource naming convention
  name_prefix = "${var.project_name}-${var.environment}"
}

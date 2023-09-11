# Create resource group
resource "azurerm_resource_group" "myrg" {
  name     = var.RG_NAME
  location = "West Europe"
  tags = {
    env = "demo"
  }
}

# Create vnet
module "agent-vnet" {
  source  = "Azure/vnet/azurerm"
  version = "4.0.0"

  vnet_name           = var.VNET_NAME
  resource_group_name = azurerm_resource_group.myrg.name
  use_for_each        = true
  vnet_location       = azurerm_resource_group.myrg.location
  address_space       = ["10.1.0.0/16"]
  subnet_names        = ["agent-subnet"]
  subnet_prefixes     = ["10.1.1.0/24"]
  tags = {
    env = "demo"
  }
}

data "azurerm_subscription" "deploy_subscription" {
  subscription_id = var.subscription_id
}

# Azure AD App
resource "azuread_application" "terraform_app" {
  display_name = "terraform_app"
}

# Service Principal associated with the Azure AD App
resource "azuread_service_principal" "terraform_spn" {
  application_id = azuread_application.terraform_app.application_id
}

# Service Principal password
resource "azuread_service_principal_password" "spn_pw" {
  service_principal_id = azuread_service_principal.terraform_spn.object_id
}

# "Contributor" Role assignment for service principal to the subscription
resource "azurerm_role_assignment" "assign_spn_tosub" {
  scope                = data.azurerm_subscription.deploy_subscription.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.terraform_spn.object_id
  depends_on = [
    azuread_service_principal.terraform_spn
  ]
}

# Create Storage account for backend config
resource "azurerm_storage_account" "backend_sa" {
  name                     = var.backend_storage_account
  resource_group_name      = azurerm_resource_group.myrg.name
  location                 = azurerm_resource_group.myrg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
  tags = {
    environment = "demo"
  }
}

resource "azurerm_storage_container" "terraform-state" {
  name                  = "terraform-state"
  storage_account_name  = azurerm_storage_account.backend_sa.name
  container_access_type = "private"
}


# Create Keyvault - use rbac for authorization of data actions

resource "azurerm_key_vault" "tf-lg-101-kv" {
  name                        = var.tf-kv
  resource_group_name         = azurerm_resource_group.myrg.name
  location                    = azurerm_resource_group.myrg.location
  tenant_id                   = var.tenant_id
  enabled_for_disk_encryption = false
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  enable_rbac_authorization   = true

  sku_name = "standard"
}

# Create role assignment to set secrets for me
resource "azurerm_role_assignment" "RoleToSetsecrets" {
  scope                = azurerm_key_vault.tf-lg-101-kv.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = "cfe4499d-9284-4f74-b189-9720b39e349b" #moi
}

# Create role assignment to read secrets for the spn used by devops connection
resource "azurerm_role_assignment" "Getsecrets" {
  scope                = azurerm_key_vault.tf-lg-101-kv.id
  role_definition_name = "Key Vault Secrets User"
  # role_definition_id = "/providers/Microsoft.Authorization/roleDefinitions/4633458b-17de-408a-b874-0445c86b69e6" # "Key Vault Secrets User" role
  # "description": "Read secret contents. Only works for key vaults that use the 'Azure role-based access control' permission model."
  principal_id = azuread_service_principal.terraform_spn.object_id
  depends_on = [
    azuread_service_principal.terraform_spn
  ]
}

# Secrets creation into KV
resource "azurerm_key_vault_secret" "backend-sa" {
  name         = "backend-sa"
  value        = var.backend_storage_account
  key_vault_id = azurerm_key_vault.tf-lg-101-kv.id
  depends_on = [
    azurerm_role_assignment.RoleToSetsecrets
  ]
}

resource "azurerm_key_vault_secret" "backend-container" {
  name         = "backend-container"
  value        = "terraform-state"
  key_vault_id = azurerm_key_vault.tf-lg-101-kv.id
  depends_on = [
    azurerm_role_assignment.RoleToSetsecrets
  ]
}

resource "azurerm_key_vault_secret" "backend-path" {
  name         = "backend-path"
  value        = "demo.tfstate"
  key_vault_id = azurerm_key_vault.tf-lg-101-kv.id
  depends_on = [
    azurerm_role_assignment.RoleToSetsecrets
  ]
}

resource "azurerm_key_vault_secret" "backend-access-key" {
  name         = "backend-access-key"
  value        = azurerm_storage_account.backend_sa.primary_access_key
  key_vault_id = azurerm_key_vault.tf-lg-101-kv.id
  depends_on = [
    azurerm_role_assignment.RoleToSetsecrets
  ]
}

resource "azurerm_key_vault_secret" "tf-spn-client-id" {
  name         = "tf-spn-client-id"
  value        = azuread_service_principal.terraform_spn.object_id
  key_vault_id = azurerm_key_vault.tf-lg-101-kv.id
  depends_on = [
    azurerm_role_assignment.RoleToSetsecrets
  ]
}

resource "azurerm_key_vault_secret" "tf-spn-secret" {
  name         = "tf-spn-secret"
  value        = azuread_service_principal_password.spn_pw.value
  key_vault_id = azurerm_key_vault.tf-lg-101-kv.id
  depends_on = [
    azurerm_role_assignment.RoleToSetsecrets
  ]
}

resource "azurerm_key_vault_secret" "tf-spn-tenant-id" {
  name         = "tf-spn-tenant-id"
  value        = var.tenant_id
  key_vault_id = azurerm_key_vault.tf-lg-101-kv.id
  depends_on = [
    azurerm_role_assignment.RoleToSetsecrets
  ]
}

# Create some VMs
module "agentlinux" {
  source    = "./modules/m-linuxvm"
  vm_name   = "agent-linux"
  vm_size   = "Standard_B2s"
  rg        = azurerm_resource_group.myrg.name
  location  = azurerm_resource_group.myrg.location
  subnet_id = module.agent-vnet.vnet_subnets[0]
}

# private link stuff for keyvault
# have to remove "Allow public access from all networks" from the portal

resource "azurerm_private_dns_zone" "keyvault_dns_zone" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.myrg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault_dns_link" {
  name                  = "keyvault_dns_link"
  resource_group_name   = azurerm_resource_group.myrg.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault_dns_zone.name
  virtual_network_id    = module.agent-vnet.vnet_id
}

resource "azurerm_private_endpoint" "keyvault_pe" {
  name                = "keyvault_pe"
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name
  subnet_id           = module.agent-vnet.vnet_subnets[0]

  private_service_connection {
    name                           = "keyvault-privateserviceconnection"
    private_connection_resource_id = azurerm_key_vault.tf-lg-101-kv.id
    subresource_names              = ["Vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "keyvault-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.keyvault_dns_zone.id]
  }
}

# private link stuff for Storage account

resource "azurerm_private_dns_zone" "storage_account_dns_zone" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.myrg.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "storage_account_dns_link" {
  name                  = "storage_account_dns_link"
  resource_group_name   = azurerm_resource_group.myrg.name
  private_dns_zone_name = azurerm_private_dns_zone.storage_account_dns_zone.name
  virtual_network_id    = module.agent-vnet.vnet_id
}

resource "azurerm_private_endpoint" "storage_pe" {
  name                = "storage_pe"
  location            = azurerm_resource_group.myrg.location
  resource_group_name = azurerm_resource_group.myrg.name
  subnet_id           = module.agent-vnet.vnet_subnets[0]

  private_service_connection {
    name                           = "storage-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.backend_sa.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "storage-dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.storage_account_dns_zone.id]
  }
}

# try to remove public access
resource "azurerm_storage_account_network_rules" "rules" {
  storage_account_id = azurerm_storage_account.backend_sa.id
  default_action     = "Deny"
  bypass             = ["Metrics", "Logging", "AzureServices"]
}
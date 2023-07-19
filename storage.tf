resource "azurerm_recovery_services_vault" "vault" {
  name                = local.storage_recovery_services_vault
  location            = local.location
  resource_group_name = local.resource_group_name
  sku                 = "Standard"
}


resource "azurerm_storage_account" "wiki-account" {
  name                     = local.storage_account_name
  resource_group_name      = local.resource_group_name
  location                 = local.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "share" {
  name                 = "${local.resource_group_name}-${local.share_name}"
  storage_account_name = azurerm_storage_account.wiki-account.name
  quota                = 5
}

resource "azurerm_storage_share_directory" "smb" {
  name                 = "${local.resource_group_name}-${local.share_directory_name}"
  share_name           = azurerm_storage_share.share.name
  storage_account_name = azurerm_storage_account.wiki-account.name
}

# Create storage/defaults variables file for ansible
resource "local_file" "storage_main_yml" {
  filename        = "${path.module}/ansible/roles/storage/defaults/main.yml"
  file_permission = "0644"
  content         = <<-EOT
# Variables to mount storage disk
storage_account_name: "${local.resource_group_name}-${local.share_name}"
storage_account_key: "${azurerm_storage_account.wiki-account.primary_access_key}"
share_name: "${local.storage_account_name}"
EOT
}

resource "azurerm_backup_container_storage_account" "protection-container" {
  resource_group_name = local.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.vault.name
  storage_account_id  = azurerm_storage_account.wiki-account.id
}

resource "azurerm_backup_policy_file_share" "storage-policy" {
  name                = "${local.resource_group_name}-${local.storage_backup_policy}"
  resource_group_name = local.resource_group_name
  recovery_vault_name = azurerm_recovery_services_vault.vault.name

  backup {
    frequency = "Daily"
    time      = "19:00"
  }

  retention_daily {
    count = 10
  }
}

resource "azurerm_backup_protected_file_share" "share1" {
  resource_group_name       = local.resource_group_name
  recovery_vault_name       = azurerm_recovery_services_vault.vault.name
  source_storage_account_id = azurerm_backup_container_storage_account.protection-container.storage_account_id
  source_file_share_name    = azurerm_storage_share.share.name
  backup_policy_id          = azurerm_backup_policy_file_share.storage-policy.id
}
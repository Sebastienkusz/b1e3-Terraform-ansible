data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "coffre_fort" {
  name                        = "b1e3gr2vault"
  location                    = local.location
  resource_group_name         = local.resource_group_name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"
}

resource "azurerm_key_vault_access_policy" "ssl" {
  for_each     = data.azuread_user.admin
  key_vault_id = azurerm_key_vault.coffre_fort.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = each.value.object_id

  key_permissions         = ["Get", "List", "Encrypt", "Decrypt"]
  certificate_permissions = ["Backup", "Create", "Delete", "DeleteIssuers", "Get", "GetIssuers", "Import", "List", "ListIssuers", "ManageContacts", "ManageIssuers", "Purge", "Recover", "Restore", "SetIssuers", "Update"]
  secret_permissions      = ["Get", "Backup", "Delete", "List", "Purge", "Recover", "Restore", "Set"]
  storage_permissions     = []
}

resource "azurerm_key_vault_certificate" "cert" {
  name         = "wikijs"
  key_vault_id = azurerm_key_vault.coffre_fort.id

  certificate_policy {
    issuer_parameters {
      name = "Self"
    }

    key_properties {
      exportable = true
      key_size   = 2048
      key_type   = "RSA"
      reuse_key  = true
    }

    lifetime_action {
      action {
        action_type = "AutoRenew"
      }

      trigger {
        days_before_expiry = 6
      }
    }

    secret_properties {
      content_type = "application/x-pkcs12"
    }

    x509_certificate_properties {
      # Server Authentication = 1.3.6.1.5.5.7.3.1
      # Client Authentication = 1.3.6.1.5.5.7.3.2
      extended_key_usage = ["1.3.6.1.5.5.7.3.1"]

      key_usage = [
        "cRLSign",
        "dataEncipherment",
        "digitalSignature",
        "keyAgreement",
        "keyCertSign",
        "keyEncipherment",
      ]

      # subject_alternative_names {
      #   dns_names = ["${azurerm_public_ip.Public_IP_Appli.fqdn}"]
      # }

      subject            = "CN=http://b1e3-gr2-wikijs.westeurope.cloudapp.azure.com"
      validity_in_months = 3
    }
  }
}

resource "azurerm_key_vault_secret" "example" {
  name         = "secret-sauce"
  value        = "szechuan"
  key_vault_id = azurerm_key_vault.coffre_fort.id
}

resource "azurerm_storage_account" "key_storage" {
  name                     = "b1e3gr2keyvaultstorage"
  resource_group_name      = local.resource_group_name
  location                 = local.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "container" {
  name                  = "container"
  storage_account_name  = azurerm_storage_account.key_storage.name
  container_access_type = "blob"
}

resource "azurerm_storage_blob" "testsb" {
  name                   = "/.well-known/acme-challenge/*"
  storage_account_name   = azurerm_storage_account.key_storage.name
  storage_container_name = azurerm_storage_container.container.name
  type                   = "Append"
}
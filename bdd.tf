

resource "azurerm_mariadb_server" "serverdb" {
  name                             = "${local.resource_group_name}-${local.server_name}"
  location                         = local.location
  resource_group_name              = local.resource_group_name
  sku_name                         = "GP_Gen5_2"
  storage_mb                       = 5120
  backup_retention_days            = 7
  geo_redundant_backup_enabled     = false
  administrator_login              = local.admin
  administrator_login_password     = local.mariadb_admin_password
  version                          = "10.3"
  ssl_enforcement_enabled          = false
  ssl_minimal_tls_version_enforced = "TLSEnforcementDisabled"
  #public_network_access_enabled = false
}

resource "azurerm_mariadb_database" "database" {
  name                = local.database_name
  resource_group_name = local.resource_group_name
  server_name         = azurerm_mariadb_server.serverdb.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_520_ci"
}

resource "azurerm_network_security_group" "nsg_mariadb" {
  name                = "${local.resource_group_name}-nsg-${local.nsg_name}"
  location            = local.location
  resource_group_name = local.resource_group_name
}

resource "azurerm_network_security_rule" "mariadb_rule" {
  name                        = "${local.resource_group_name}-${local.nsg_rule_name}"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = local.nsg_bdd_rule_mysqlport
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = local.resource_group_name
  network_security_group_name = azurerm_network_security_group.NSG_Appli.name
}

#Create private dns zone
resource "azurerm_private_dns_zone" "dnszone" {
  name                = local.mariadb_private_dns_zone
  resource_group_name = local.resource_group_name
}

#Create a link between private dns zone and virtual network
resource "azurerm_private_dns_zone_virtual_network_link" "vnetlink" {
  name                  = local.mariadb_private_dns_link
  resource_group_name   = local.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.dnszone.name
  virtual_network_id    = azurerm_virtual_network.VNet.id
}

#Create endpoint
resource "azurerm_private_endpoint" "pep" {
  name                = local.mariadb_private_endpoint
  location            = local.location
  resource_group_name = local.resource_group_name
  subnet_id           = azurerm_subnet.Subnet["sr2"].id

  private_service_connection {
    name                           = "mariadbprivatelink"
    is_manual_connection           = false
    private_connection_resource_id = azurerm_mariadb_server.serverdb.id
    subresource_names              = ["mariadbServer"]
  }

  private_dns_zone_group {
    name                 = "dns-zone-group"
    private_dns_zone_ids = [azurerm_private_dns_zone.dnszone.id]
  }
}

#Get endpoint connection informations
data "azurerm_private_endpoint_connection" "private-ip" {
  name                = azurerm_private_endpoint.pep.name
  resource_group_name = local.resource_group_name
  depends_on          = [azurerm_mariadb_server.serverdb]
}

#Create private dns record in the private dns zone
resource "azurerm_private_dns_a_record" "dnsrecord" {
  name                = "${local.resource_group_name}-dns"
  zone_name           = azurerm_private_dns_zone.dnszone.name
  resource_group_name = local.resource_group_name
  ttl                 = 300
  records             = [data.azurerm_private_endpoint_connection.private-ip.private_service_connection[0].private_ip_address]
}
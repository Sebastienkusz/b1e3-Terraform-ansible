# Virtual Network
resource "azurerm_virtual_network" "VNet" {
  name                = "${local.resource_group_name}-${local.network_name}"
  address_space       = [local.network_base]
  location            = local.location
  resource_group_name = local.resource_group_name
  tags                = local.tags
}

# Subnets 
resource "azurerm_subnet" "Subnet" {
  for_each             = local.subnets
  name                 = "${local.resource_group_name}-${each.key}"
  resource_group_name  = local.resource_group_name
  virtual_network_name = azurerm_virtual_network.VNet.name
  address_prefixes     = [each.value]
  #enforce_private_link_service_network_policies = true
}
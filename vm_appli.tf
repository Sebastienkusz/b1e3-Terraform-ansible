# NSG Group - Appli
resource "azurerm_network_security_group" "NSG_Appli" {
  name                = "${local.resource_group_name}-nsg-${local.appli_name}"
  location            = local.location
  resource_group_name = local.resource_group_name
}

# NSG Rule - HTTP Port - Appli
resource "azurerm_network_security_rule" "NSG_Appli_Rules_HTTP" {
  name                        = "HTTP_Rule"
  priority                    = 1010
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "3000"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = local.resource_group_name
  network_security_group_name = azurerm_network_security_group.NSG_Appli.name
}

# NSG Rule - HTTPS Port - Appli
resource "azurerm_network_security_rule" "NSG_Appli_Rules_HTTPS" {
  name                        = "HTTPS_Rule"
  priority                    = 1020
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  resource_group_name         = local.resource_group_name
  network_security_group_name = azurerm_network_security_group.NSG_Appli.name
}

# Public IP and Label DNS - Appli
resource "azurerm_public_ip" "Public_IP_Appli" {
  name                = "${local.resource_group_name}-public_ip-${local.appli_name}"
  resource_group_name = local.resource_group_name
  location            = local.location
  allocation_method   = local.public_ip_appli_allocation
  domain_name_label   = local.public_ip_appli_dns_name
  ip_version          = local.public_ip_appli_version
  sku                 = local.public_ip_appli_sku
  tags                = local.tags
}

# NIC - Appli
resource "azurerm_network_interface" "Nic_Appli" {
  name                = "${local.resource_group_name}-nic-${local.appli_name}"
  location            = local.location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "${local.resource_group_name}-nic-${local.appli_name}-private_ip"
    subnet_id                     = azurerm_subnet.Subnet["sr1"].id
    private_ip_address_allocation = "Dynamic"
  }
}

# Association NIC - NSG - Appli
resource "azurerm_network_interface_security_group_association" "Appli" {
  network_interface_id      = azurerm_network_interface.Nic_Appli.id
  network_security_group_id = azurerm_network_security_group.NSG_Appli.id
}

# VM - Appli
resource "azurerm_linux_virtual_machine" "VM_Appli" {
  name                            = "${local.resource_group_name}-vm-${local.appli_name}"
  location                        = local.location
  resource_group_name             = local.resource_group_name
  network_interface_ids           = [azurerm_network_interface.Nic_Appli.id]
  size                            = local.vm_appli_size
  admin_username                  = local.admin
  computer_name                   = local.appli_name
  disable_password_authentication = true

  admin_ssh_key {
    username   = local.admin
    public_key = tls_private_key.admin_rsa.public_key_openssh
  }

  os_disk {
    name                 = "${local.resource_group_name}-os_disk-${local.appli_name}"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = "30"
  }
  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
  tags = local.tags

  # provisioner "local-exec" {
  #   command     = "/bin/rm -rf /mnt/${azurerm_storage_share.share.name}/${azurerm_storage_share_directory.smb.name}/${local.appli_name}"
  #   interpreter = ["bash"]
  #   when        = destroy
  # }

  depends_on = [
    local_file.admin_rsa_file
  ]
}
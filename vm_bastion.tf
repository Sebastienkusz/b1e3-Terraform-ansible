# NSG Group - Bastion
resource "azurerm_network_security_group" "NSG_Bastion" {
  name                = "${local.resource_group_name}-nsg-${local.bastion_name}"
  location            = local.location
  resource_group_name = local.resource_group_name
}

# NSG Rule - SSH Port - Bastion
resource "azurerm_network_security_rule" "NSG_Bastion_Rules" {
  name                        = "SSH_Rule"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = local.nsg_bastion_rule_sshport
  source_address_prefix       = local.nsg_bastion_rule_ipfilter
  destination_address_prefix  = "*"
  resource_group_name         = local.resource_group_name
  network_security_group_name = azurerm_network_security_group.NSG_Bastion.name
}

# Public IP and Label DNS - Bastion
resource "azurerm_public_ip" "Public_IP_Bastion" {
  name                = "${local.resource_group_name}-public_ip-${local.bastion_name}"
  resource_group_name = local.resource_group_name
  location            = local.location
  allocation_method   = local.public_ip_bastion_allocation
  domain_name_label   = local.public_ip_bastion_dns_name
  ip_version          = local.public_ip_bastion_version
  sku                 = local.public_ip_bastion_sku
  tags                = local.tags
}

# NIC - Bastion
resource "azurerm_network_interface" "Nic_Bastion" {
  name                = "${local.resource_group_name}-nic-${local.bastion_name}"
  location            = local.location
  resource_group_name = local.resource_group_name

  ip_configuration {
    name                          = "${local.resource_group_name}-nic-${local.bastion_name}-private_ip"
    subnet_id                     = azurerm_subnet.Subnet["sr1"].id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.Public_IP_Bastion.id
  }
}

# Association NIC - NSG - Bastion
resource "azurerm_network_interface_security_group_association" "Bastion" {
  network_interface_id      = azurerm_network_interface.Nic_Bastion.id
  network_security_group_id = azurerm_network_security_group.NSG_Bastion.id
}

# VM - Bastion
resource "azurerm_linux_virtual_machine" "VM_Bastion" {
  name                            = "${local.resource_group_name}-vm-${local.bastion_name}"
  location                        = local.location
  resource_group_name             = local.resource_group_name
  network_interface_ids           = [azurerm_network_interface.Nic_Bastion.id]
  size                            = local.vm_bastion_size
  admin_username                  = local.admin
  computer_name                   = local.bastion_name
  disable_password_authentication = true

  admin_ssh_key {
    username   = local.admin
    public_key = tls_private_key.admin_rsa.public_key_openssh
  }

  # admin_ssh_key {
  #   username   = local.admin
  #   public_key = file("${abspath(path.root)}/ssh_keys/sebastien.pub")
  # }

  # admin_ssh_key {
  #   username   = local.admin
  #   public_key = file("${abspath(path.root)}/ssh_keys/johann.pub")
  # }

  os_disk {
    name                 = "${local.resource_group_name}-os_disk-${local.bastion_name}"
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

  depends_on = [
    local_file.admin_rsa_file
  ]
}
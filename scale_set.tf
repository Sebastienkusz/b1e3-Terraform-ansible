# action plan 10. Create VMs Scale Set
resource "azurerm_linux_virtual_machine_scale_set" "scale" {
  name                            = "${local.resource_group_name}-${local.scale_name}"
  location                        = local.location
  resource_group_name             = local.resource_group_name
  upgrade_mode                    = "Manual"
  sku                             = local.scale_size
  instances                       = 2
  admin_username                  = local.admin
  disable_password_authentication = true

  admin_ssh_key {
    username   = local.admin
    public_key = tls_private_key.admin_rsa.public_key_openssh
  }

  network_interface {
    name    = "${local.resource_group_name}-${local.scale_network_name}"
    primary = true

    ip_configuration {
      name      = "${local.resource_group_name}-${local.scale_ip_name}"
      primary   = true
      subnet_id = azurerm_subnet.Subnet["sr1"].id
    }
  }

  os_disk {
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

  # lifecycle {
  #   ignore_changes = ["instances"]
  # }
}

# action plan 11. Auto-scaling
resource "azurerm_monitor_autoscale_setting" "autoscale" {
  name                = "${local.resource_group_name}-${local.autoscale_name}"
  resource_group_name = local.resource_group_name
  location            = local.location
  target_resource_id  = azurerm_linux_virtual_machine_scale_set.scale.id

  profile {
    name = "${local.resource_group_name}-${local.autoscale_profile}"

    capacity {
      default = 2
      minimum = 2
      maximum = 8
    }

    rule {
      metric_trigger {
        metric_name        = local.autoscale_rule_metric_name
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.scale.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 90
        # metric_namespace   = "microsoft.compute/virtualmachinescalesets"
        # dimensions {
        #   name     = "AppName"
        #   operator = "Equals"
        #   values   = ["App1"]
      }

      scale_action {
        direction = "Increase"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = local.autoscale_rule_metric_name
        metric_resource_id = azurerm_linux_virtual_machine_scale_set.scale.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT5M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
      }

      scale_action {
        direction = "Decrease"
        type      = "ChangeCount"
        value     = "1"
        cooldown  = "PT1M"
      }

      #   predictive {
      #     scale_mode = "Enabled"
      #     #look_ahead_time = "PT5M"
      #   }
    }
  }
}
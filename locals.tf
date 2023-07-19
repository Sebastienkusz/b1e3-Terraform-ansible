# Subscription and admin name
locals {
  subscription_id     = "c56aea2c-50de-4adc-9673-6a8008892c21"
  admin               = "azureuser"
  resource_group_name = "b1e3-gr2"
  dns_prefix          = "b1e3-gr2"
  location            = data.azurerm_resource_group.current.location
}

# Add users (only 2 users)
locals {
  users = {
    user1 = {
      name   = "johann"
      sshkey = "johann"
      email  = "jlabat@simplonformations.onmicrosoft.com"
    }
    user2 = {
      name   = "sebastien"
      sshkey = "sebastien"
      email  = "skusz@simplonformations.onmicrosoft.com"
    }
  }
}

# Network (only 3 subnets)
locals {
  network_base = "10.1.0.0/16"
  network_name = "vnet"
  subnets = {
    "sr1" = "10.1.0.0/24"
    "sr2" = "10.1.1.0/24"
    "gw"  = "10.1.2.0/24"
  }
}

# VM Bastion
locals {
  bastion_name                 = "bastion"
  nsg_bastion_rule_ipfilter    = "*" #"82.126.234.200" # IP Box 
  nsg_bastion_rule_sshport     = "22"
  public_ip_bastion_version    = "IPv4"
  public_ip_bastion_dns_name   = "${local.dns_prefix}-${local.bastion_name}"
  public_ip_bastion_sku        = "Standard" # Basic or Standard
  public_ip_bastion_allocation = "Static"   # Static or Dynamic
  vm_bastion_size              = "Standard_B2s"
}

# VM wiki-js
locals {
  appli_name                 = "wiki-js"
  public_ip_appli_version    = "IPv4"
  public_ip_appli_dns_name   = "${local.dns_prefix}-${local.appli_name}"
  public_ip_appli_sku        = "Standard" # Basic or Standard
  public_ip_appli_allocation = "Static"   # Static or Dynamic
  vm_appli_size              = "Standard_D2s_v3"
  appli_archive_url          = "https://github.com/Requarks/wiki/releases/latest/download/wiki-js.tar.gz"
  appli_archive_name         = basename("${local.appli_archive_url}")
  appli_service              = regex("[a-z]+", "${local.appli_name}") # trim("${local.appli_name}", "-")
}

# bdd
locals {
  server_name              = "mariaserverdb"
  database_name            = "b1e3gr2mariadb"
  nsg_name                 = "mariadb"
  nsg_rule_name            = "mariadb_rule"
  nsg_bdd_rule_mysqlport   = "3306"
  mariadb_admin_password   = random_password.admin_mariadb.result
  mariadb_user             = "wikiuser"
  mariadb_user_password    = random_password.user_mariadb.result
  mariadb_private_dns_zone = "privatelink.mariadb.database.azure.com"
  mariadb_private_dns_link = "dnsvnetlink"
  mariadb_private_endpoint = "pep"
}

# Storage account
locals {
  storage_recovery_services_vault = "recoveryservicesvault"
  storage_account_name            = "b1e3gr2wikistorage"
  share_directory_name            = "wikispace"
  share_name                      = "wikishare"
  storage_backup_policy           = "recovery-vault-policy"
}

# Passerelle d'application
locals {
  # HTTP
  backend_address_pool_name      = "${local.resource_group_name}-beap"
  frontend_port_name             = "${local.resource_group_name}-porthttp"
  frontend_ip_configuration_name = "${local.resource_group_name}-feip"
  http_setting_name              = "${local.resource_group_name}-be-htst"
  listener_name                  = "${local.resource_group_name}-httplstn"
  request_routing_rule_name      = "${local.resource_group_name}-rqrt"
  redirect_configuration_name    = "${local.resource_group_name}-rdrcfg"
  # HTTPS
  frontend_port_name_https             = "${local.resource_group_name}-porthttps"
  listener_name_https                  = "${local.resource_group_name}-httpslstn"
  frontend_ip_configuration_name_https = "${local.resource_group_name}-feiphttps"
  ssl_certificate_name                 = "${local.resource_group_name}-cert"
}

# Scale set
locals {
  scale_name                 = "scale"
  scale_size                 = "Standard_D2s_v3"
  scale_network_name         = "scale_network"
  scale_ip_name              = "scale_ip"
  autoscale_name             = "AutoscaleSetting"
  autoscale_profile          = "Autoscaling"
  autoscale_rule_metric_name = "Percentage CPU"
}

locals {
  tags = {
    Development = basename(abspath(path.root))
    Owner       = local.admin
    DeployID    = formatdate("YYYY-MM-DD", time_static.main.rfc3339)
    Environment = "Preproduction"
  }
}
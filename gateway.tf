resource "azurerm_user_assigned_identity" "bonne" {
  location            = local.location
  name                = "${local.resource_group_name}-user_assigned"
  resource_group_name = local.resource_group_name
}

resource "azurerm_application_gateway" "main" {
  name                = "${local.resource_group_name}-gateway"
  resource_group_name = local.resource_group_name
  location            = local.location

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.bonne.id]
  }

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "gateway-ip"
    subnet_id = azurerm_subnet.Subnet["gw"].id
  }

  frontend_ip_configuration {
    name                          = local.frontend_ip_configuration_name
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.Public_IP_Appli.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_port {
    name = local.frontend_port_name_https
    port = 443
  }

  # HTTP
  http_listener {
    name                           = local.listener_name
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  # HTTPS
  http_listener {
    name                           = local.listener_name_https
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.frontend_port_name_https
    protocol                       = "Https"
    ssl_certificate_name           = "ssl_cert"
  }

  ssl_certificate {
    name                = "ssl_cert"
    key_vault_secret_id = azurerm_key_vault_certificate.cert.secret_id
  }

  backend_address_pool {
    name         = local.backend_address_pool_name
    ip_addresses = [azurerm_public_ip.Public_IP_Appli.ip_address]
  }

  backend_http_settings {
    name                  = local.http_setting_name
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 3000
    protocol              = "Http"
    request_timeout       = 60
    probe_name            = "b1e3-gr2-probe"
  }

  probe {
    name                = "b1e3-gr2-probe"
    host                = "127.0.0.1"
    interval            = 30
    timeout             = 30
    unhealthy_threshold = 3
    protocol            = "Http"
    port                = 80
    path                = "/"
  }

  # HTTP rule
  request_routing_rule {
    name               = local.request_routing_rule_name
    rule_type          = "PathBasedRouting"
    http_listener_name = local.listener_name
    url_path_map_name  = "Challenge"
    priority           = 2
  }

  url_path_map {
    name                               = "Challenge"
    default_backend_address_pool_name  = local.backend_address_pool_name
    default_backend_http_settings_name = local.http_setting_name
    path_rule {
      name                        = "Challenge_rule"
      paths                       = ["/.well-known/acme-challenge/*"]
      redirect_configuration_name = local.redirect_configuration_name
    }
  }

  # HTTPS rule
  request_routing_rule {
    name                        = "routing_https"
    rule_type                   = "Basic"
    http_listener_name          = local.listener_name_https
    redirect_configuration_name = local.redirect_configuration_name
    priority                    = 1
    # backend_address_pool_name   = local.backend_address_pool_name
    # backend_http_settings_name  = local.http_setting_name
  }

  redirect_configuration {
    name                 = local.redirect_configuration_name
    target_url           = azurerm_storage_container.container.id
    redirect_type        = "Permanent"
    include_path         = true
    include_query_string = true
  }

  depends_on = [
    local_file.appli_commun_main_yml
  ]
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "nic-assoc" {
  network_interface_id    = azurerm_network_interface.Nic_Appli.id
  ip_configuration_name   = "${local.resource_group_name}-nic-${local.appli_name}-private_ip"
  backend_address_pool_id = tolist(azurerm_application_gateway.main.backend_address_pool).0.id
}

resource "random_password" "password" {
  length  = 16
  special = true
  lower   = true
  upper   = true
  numeric = true
}

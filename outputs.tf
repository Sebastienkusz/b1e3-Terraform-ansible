output "db_password" {
  value     = azurerm_mariadb_server.serverdb.administrator_login_password
  sensitive = true
}
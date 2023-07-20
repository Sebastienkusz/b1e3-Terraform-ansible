# Data to declare the location of the resource group
data "azurerm_resource_group" "current" {
  name = local.resource_group_name
}

# Resource to fix time for the tfstate
resource "time_static" "main" {}

# Data source to get admin users' object_id and use it in the key vault access policy

# locals {
#   admin_users = {
#     "${local.users["user1"]["name"]}" = "${local.users["user1"]["email"]}"
#     "${local.users["user2"]["name"]}" = "${local.users["user2"]["email"]}"
#   }
# }

# data "azuread_user" "admin" {
#   for_each            = local.admin_users
#   user_principal_name = each.value
# }

data "azuread_user" "admin" {
  for_each            = local.users
  user_principal_name = each.value.email
}
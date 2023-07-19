terraform {
  backend "azurerm" {
    resource_group_name  = "b1e3-gr2"
    storage_account_name = "b1e3terraformtfstate"
    container_name       = "tfstate"
    key                  = "wikijs-tfstate/terraform.tfstate"
  }
}
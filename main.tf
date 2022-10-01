terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.25.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}

# Create a resource group
resource "azurerm_resource_group" "copamonitor-rg" {
  name     = "copamonitor-rg"
  location = "South Central US"
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "copanet1-vn" {
  name                = "copanet1-vn"
  resource_group_name = azurerm_resource_group.copamonitor-rg.name
  location            = azurerm_resource_group.copamonitor-rg.location
  address_space       = ["10.0.0.0/16"]
}
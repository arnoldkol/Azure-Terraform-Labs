terraform {
  required_providers {
      azurerm = {
          source = "hashicorp/azurerm"
          version = "=2.48.0"
        }
    }
}
provider "azurerm" {
  features {}      
}


#Creates a logical container where resources are deployed
resource "azurerm_resource_group" "rg" {
  name     = var.rg_name
  location = var.rg_location
}

#creates a virtual network
resource "azurerm_network_security_group" "example" {
  name                = "acceptanceTestSecurityGroup1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_virtual_network" "vnet" {
  name                = "virtualNetwork1"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]

  tags = {
    environment = "Production"
  }
}

#creates a subnet
resource "azurerm_subnet" "sub" {
  name                 = "sub1"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

#creates a virtual machine scale set
resource "azurerm_windows_virtual_machine_scale_set" "ss" {
  name                = "first-vmss"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = var.sku_vm
  instances           = 3
  admin_password      = "P@55w0rd1234!"
  admin_username      = "adminuser"

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter-Server-Core"
    version   = "latest"
  }

  os_disk {
    storage_account_type = var.sa_type
    caching              = "ReadWrite"
  }

  network_interface {
    name    = "nic"
    primary = true

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.sub.id
    }
  }
}
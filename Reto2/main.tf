
terraform {
  required_providers {
    azurerm = {
      source = "hashicorp/azurerm"
      version = "3.25.0"
    }
  }
}

provider "azurerm" {
  # Configuration options
  features {
    
  }
}
resource "azurerm_resource_group" "RG-PROD-01" {
  name     = "RG-PROD-01"
  location = "EastUS 2"

   
   tags = {
    AMBIENTE = "PRD"
    CREATEDBY = "los copatoon"
    DPT = "VENTAS"
  }
}
#  VIRTUAL NETWORK

resource "azurerm_virtual_network" "vnet" {
  name                = "VNET-PROD"
  address_space       = ["10.150.0.0/16"]
  location            = azurerm_resource_group.RG-PROD-01.location
  resource_group_name = azurerm_resource_group.RG-PROD-01.name

   tags = {
    AMBIENTE = "PRD"
    CREATEDBY = "los copatoon"
    DPT = "VENTAS"
  }
}


#   VIRTUAL SUBNET
resource "azurerm_subnet" "subnet-copa" {
  name                 = "Subnet-01"
  resource_group_name  = azurerm_resource_group.RG-PROD-01.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.150.0.0/24"]

}

resource "azurerm_network_interface" "network-if" {
  name                = "network_if"
  location            = azurerm_resource_group.RG-PROD-01.location
  resource_group_name = azurerm_resource_group.RG-PROD-01.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet-copa.id
    private_ip_address_allocation = "Dynamic"
  }
   tags = {
    AMBIENTE = "PRD"
    CREATEDBY = "los copatoon"
    DPT = "VENTAS"
  }
}


# MAQUINA VIRTUAL DE LINUX
resource "azurerm_linux_virtual_machine" "linux-vm" {
  name                = "SRV-PROD-02-AZ"
  resource_group_name = azurerm_resource_group.RG-PROD-01.name
  location            = azurerm_resource_group.RG-PROD-01.location
  size                = "Standard_B2s"
  admin_username      = "copatoon"
  admin_password      = "Copatoon2022"  
  network_interface_ids = [
    azurerm_network_interface.network-if.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb    = "60"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "16.04-LTS"
    version   = "latest"
  }
   tags = {
    AMBIENTE = "PRD"
    CREATEDBY = "Los copatoon"
    DPT = "VENTAS"
  }
}


# MAQUINA VIRTUAL DE WINDOWS

resource "azurerm_windows_virtual_machine" "windows-vm" {
  name                = "SRV-PROD-01-AZ"
  resource_group_name = azurerm_resource_group.RG-PROD-01.name
  location            = azurerm_resource_group.RG-PROD-01.location
  size                = "Standard_B2s"
  admin_username      = "copatoon"
  admin_password      = "Copatoon2022"
  network_interface_ids = [
    azurerm_network_interface.network-if.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
    disk_size_gb    = "128"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
  
  tags = {
    AMBIENTE = "PRD"
    CREATEDBY = "Los copatoon"
    DPT = "VENTAS"
    }
    
}

# IP PUBLICA PARA windows
resource "azurerm_public_ip" "windows-PublicIp1" {
  name                = "PIP-SRV-PROD-01-AZ"
  resource_group_name = azurerm_resource_group.RG-PROD-01.name
  location            = azurerm_resource_group.RG-PROD-01.location
  allocation_method   = "Static"
  
  tags = {
    AMBIENTE = "PRD"
    CREATEDBY = "Los copatoon"
    DPT = "VENTAS"
    }
}

# IP PUBLICA PARA Linux
resource "azurerm_public_ip" "linux-PublicIp1" {
  name                = "PIP-SRV-PROD-02-AZ"
  resource_group_name = azurerm_resource_group.RG-PROD-01.name
  location            = azurerm_resource_group.RG-PROD-01.location
  allocation_method   = "Static"
  
  tags = {
    AMBIENTE = "PRD"
    CREATEDBY = "Los copatoon"
    DPT = "VENTAS"
    }
}

# BACKUP Pde la app
resource "azurerm_recovery_services_vault" "backupservices-vault" {
  name                = "tfex-recovery-vault"
  location            = azurerm_resource_group.RG-PROD-01.location
  resource_group_name = azurerm_resource_group.RG-PROD-01.name
  sku                 = "Standard"
}

resource "azurerm_backup_policy_vm" "backup-policy" {
  name                = "tfex-recovery-vault-policy"
  resource_group_name = azurerm_resource_group.RG-PROD-01.name
  recovery_vault_name = azurerm_recovery_services_vault.backupservices-vault.name

  timezone = "UTC"

  backup {
    frequency = "Daily"
    time      = "23:00"
  }

  retention_daily {
    count = 10
  }

  retention_weekly {
    count    = 42
    weekdays = ["Sunday", "Wednesday", "Friday", "Saturday"]
  }

  retention_monthly {
    count    = 7
    weekdays = ["Sunday", "Wednesday"]
    weeks    = ["First", "Last"]
  }

  retention_yearly {
    count    = 77
    weekdays = ["Sunday"]
    weeks    = ["Last"]
    months   = ["January"]
  }
}

  #Insights para algo

resource "azurerm_application_insights" "appi" {
  name                = "tf-test-appinsights"
  location            = azurerm_resource_group.RG-PROD-01.location
  resource_group_name = azurerm_resource_group.RG-PROD-01.name
  application_type    = "web"
}




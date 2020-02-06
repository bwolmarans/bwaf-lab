# Configure the Azure Provider
provider "azurerm" {
  # whilst the `version` attribute is optional, we recommend pinning to a given version of the Provider
  version = "=1.43.0"
}

# Gather resource group name
variable "rg_name" {
  type        = string
  description = "Enter the resource group to create resources in. For SEs at Barracuda Networks, this is typically Firstname_Lastname (e.g. John_Smith) "
}


# Create the resource group
resource "azurerm_resource_group" "rg_playground" {
    name     = var.rg_name
    location = "eastus"

    tags = {
        environment = "Terraform BWAF"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "network_playground" {
    name                = "network_playground"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = azurerm_resource_group.rg_playground.name

    tags = {
        environment = "Terraform BWAF"
    }
}

# Create subnet
resource "azurerm_subnet" "subnet_playground" {
    name                 = "subnet_playground"
    resource_group_name  = azurerm_resource_group.rg_playground.name
    virtual_network_name = azurerm_virtual_network.network_playground.name
    address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "public_ip_ubuntu" {
    name                         = "public_ip_ubuntu"
    location                     = "eastus"
    resource_group_name          = azurerm_resource_group.rg_playground.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform BWAF"
    }
}

resource "azurerm_public_ip" "public_ip_bwaf" {
    name                         = "public_ip_bwaf"
    location                     = "eastus"
    resource_group_name          = azurerm_resource_group.rg_playground.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform BWAF"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "nsg_playground" {
    name                = "nsg_playground"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.rg_playground.name
    
    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "80"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "8080"
        priority                   = 1003
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8080"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "8K"
        priority                   = 1004
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8000"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    

    tags = {
        environment = "Terraform BWAF"
    }
}

# Create network interface
resource "azurerm_network_interface" "nic_bwaf" {
    name                      = "nic_bwaf"
    location                  = "eastus"
    resource_group_name       = azurerm_resource_group.rg_playground.name
    network_security_group_id = azurerm_network_security_group.nsg_playground.id

    ip_configuration {
        name                          = "nic_cfg_bwaf"
        subnet_id                     = azurerm_subnet.subnet_playground.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.public_ip_bwaf.id
    }

    tags = {
        environment = "Terraform BWAF"
    }
}

# Create network interface
resource "azurerm_network_interface" "nic_ubuntu" {
    name                      = "nic_ubuntu"
    location                  = "eastus"
    resource_group_name       = azurerm_resource_group.rg_playground.name
    network_security_group_id = azurerm_network_security_group.nsg_playground.id

    ip_configuration {
        name                          = "nic_cfg_ubuntu"
        subnet_id                     = azurerm_subnet.subnet_playground.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.public_ip_ubuntu.id
    }

    tags = {
        environment = "Terraform BWAF"
    }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.rg_playground.name
    }
    
    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "sa_ubuntu" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.rg_playground.name
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Terraform BWAF"
    }
}

data "azurerm_public_ip" "public_ip_bwaf" {
    name                = "${azurerm_public_ip.public_ip_bwaf.name}"
    resource_group_name = var.rg_name
}
output "public_ip_address" {
    value = "${data.azurerm_public_ip.public_ip_bwaf.ip_address}"
}   



#create bwaf
resource "azurerm_virtual_machine" "vm_bwaf" {
    name                  = "vm_bwaf"
    location              = "eastus"
    plan {
      publisher          = "barracudanetworks"
      name               = "hourly"
      product            = "waf"
    }
    
    resource_group_name   = azurerm_resource_group.rg_playground.name
    network_interface_ids = [azurerm_network_interface.nic_bwaf.id]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "osdisk_bwaf"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "barracudanetworks"
        offer     = "waf"
        sku       = "hourly"
        version   = "latest"
    }
	
    os_profile {
        computer_name  = "vm-bwaf"
        admin_username = "not_used"
        admin_password = "Hello123456!"
        custom_data = "{\"signature\": \"WaaS_Support\", \"email\": \"WaaS_Support@barracuda.com\", \"organization\": \"Barracuda Networks, Inc.\"}"
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }
    
    tags = {
        environment = "Terraform BWAF"
    }
  
}

# Create virtual machine
resource "azurerm_virtual_machine" "vm_ubuntu" {
    name                  = "vm_ubuntu"
    location              = "eastus"
    resource_group_name   = azurerm_resource_group.rg_playground.name
    network_interface_ids = [azurerm_network_interface.nic_ubuntu.id]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "osdisk_ubuntu"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04.0-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "vm-ubuntu"
        admin_username = "azureuser"
    }

    os_profile_linux_config {
        disable_password_authentication = true
        ssh_keys {
            path     = "/home/azureuser/.ssh/authorized_keys"
            key_data = "${file("~/.ssh/id_rsa.pub")}"        
        }
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = azurerm_storage_account.sa_ubuntu.primary_blob_endpoint
    }

    tags = {
        environment = "Terraform BWAF"
    }

}


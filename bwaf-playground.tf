# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "myterraformgroup" {
    name     = "bwaf_tf_rg"
    location = "eastus"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "bwaf_tf_vnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = azurerm_resource_group.myterraformgroup.name

    tags = {
        environment = "Terraform Demo"
    }
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "bwaf_tf_subnet"
    resource_group_name  = azurerm_resource_group.myterraformgroup.name
    virtual_network_name = azurerm_virtual_network.myterraformnetwork.name
    address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip2" {
    name                         = "bwaf_tf_publicip2"
    location                     = "eastus"
    resource_group_name          = azurerm_resource_group.myterraformgroup.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform Demo"
    }
}

resource "azurerm_public_ip" "myterraformpublicip1" {
    name                         = "bwaf_tf_publicip1"
    location                     = "eastus"
    resource_group_name          = azurerm_resource_group.myterraformgroup.name
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "bwaf_tf_nsg"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.myterraformgroup.name
    
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
        name                       = "8K"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "8000"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    tags = {
        environment = "Terraform Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic1" {
    name                      = "bwaf_tf_nic1"
    location                  = "eastus"
    resource_group_name       = azurerm_resource_group.myterraformgroup.name
    network_security_group_id = azurerm_network_security_group.myterraformnsg.id

    ip_configuration {
        name                          = "bwaf_tf_niccfg1"
        subnet_id                     = azurerm_subnet.myterraformsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.myterraformpublicip1.id
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic2" {
    name                      = "bwaf_tf_nic2"
    location                  = "eastus"
    resource_group_name       = azurerm_resource_group.myterraformgroup.name
    network_security_group_id = azurerm_network_security_group.myterraformnsg.id

    ip_configuration {
        name                          = "bwaf_tf_niccfg2"
        subnet_id                     = azurerm_subnet.myterraformsubnet.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.myterraformpublicip2.id
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.myterraformgroup.name
    }
    
    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mystorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.myterraformgroup.name
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Terraform Demo"
    }
}

data "azurerm_public_ip" "myterraformpublicip1" {
    name                = "${azurerm_public_ip.myterraformpublicip1.name}"
    resource_group_name = "bwaf_tf_rg"
}
output "public_ip_address" {
    value = "${data.azurerm_public_ip.myterraformpublicip1.ip_address}"
}   



#create bwaf
resource "azurerm_virtual_machine" "myterraformbwaf" {
    name                  = "bwaf_tf_vmbwaf"
    location              = "eastus"
    plan {
      publisher          = "barracudanetworks"
      name               = "hourly"
      product            = "waf"
    }
    
    resource_group_name   = azurerm_resource_group.myterraformgroup.name
    network_interface_ids = [azurerm_network_interface.myterraformnic1.id]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "bwaf_tf_osdisk"
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
        computer_name  = "bwaf-tf-vmbwaf"
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
#    provisioner "local-exec" {
##       command = "echo ${aws_instance.web.private_ip} >> private_ips.txt"
#       command = "echo Hello >> helloworld.txt"
#       command = "curl -v 'http://104.211.59.35:8000/' -H 'Content-Type: application/x-www-form-urlencoded' --data 'name_sign=dddadsfasd&email_sign=itsbrett%40gmail.com&company_sign=None&eula_hash_val=ed4480205f84cde3e6bdce0c987348d1d90de9db&action=save_signed_eula'"
#    }   
}

# Create virtual machine
resource "azurerm_virtual_machine" "myterraformvm" {
    name                  = "bwaf_tf_vmubunutu"
    location              = "eastus"
    resource_group_name   = azurerm_resource_group.myterraformgroup.name
    network_interface_ids = [azurerm_network_interface.myterraformnic2.id]
    vm_size               = "Standard_DS1_v2"

    storage_os_disk {
        name              = "bwaf_tf_osdisk2"
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
        computer_name  = "bwaf-tf-vmubuntu"
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
        storage_uri = azurerm_storage_account.mystorageaccount.primary_blob_endpoint
    }

    tags = {
        environment = "Terraform BWAF"
    }
#    provisioner "local-exec" {
##       command = "echo ${aws_instance.web.private_ip} >> private_ips.txt"
#       command = "echo Hello >> helloworld.txt"
#       command = "curl -v 'http://104.211.59.35:8000/' -H 'Content-Type: application/x-www-form-urlencoded' --data 'name_sign=dddadsfasd&email_sign=itsbrett%40gmail.com&company_sign=None&eula_hash_val=ed4480205f84cde3e6bdce0c987348d1d90de9db&action=save_signed_eula'"
       #command = "ping 8.8.8.8"
       #command = "sleep 120; ping '${azurerm_virtual_machine.myterraformvm.public_ip}'"
#    }

}

terraform {
  required_providers {
    azurerm = {
        source = "hashicorp/azurerm"
        version = "~> 3.0"
    }
  }
  required_version = ">= 1.3.0"
  }

provider "azurerm" {
    features {}
    skip_provider_registration = true
    ## Critical for sandbox — skips subscription-level provider registration
}
  data "azurerm_resource_group" "sandbox" {
    name = var.resource_group_name
    
  }

resource "azurerm_virtual_network" "main" {
    name                = "${var.prefix}-vnet"
    address_space       = ["10.0.0.0/16"]
    resource_group_name = data.azurerm_resource_group.sandbox.name
    location            = data.azurerm_resource_group.sandbox.location
}

resource "azurerm_subnet" "main" {
    name                 = "${var.prefix}-subnet"
    resource_group_name  = data.azurerm_resource_group.sandbox.name
    virtual_network_name = azurerm_virtual_network.main.name
    address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_security_group" "main" {
    name               = "${var.prefix}-nsg"
    resource_group_name = data.azurerm_resource_group.sandbox.name
    location            = data.azurerm_resource_group.sandbox.location

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
        name                       = "HTTP"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
}

resource "azurerm_subnet_network_security_group_association" "name" {
  subnet_id = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_public_ip" "main" {
    name                = "${var.prefix}-public-ip"
    resource_group_name = data.azurerm_resource_group.sandbox.name
    location            = data.azurerm_resource_group.sandbox.location
    allocation_method   = "Static"
    sku                 = "Standard"
}

resource "azurerm_network_interface" "main" {
    name                = "${var.prefix}-nic"
    resource_group_name = data.azurerm_resource_group.sandbox.name
    location            = data.azurerm_resource_group.sandbox.location

    ip_configuration {
        name                          = "internal"
        subnet_id                     = azurerm_subnet.main.id
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = azurerm_public_ip.main.id
    }
}

resource "azurerm_linux_virtual_machine" "main" {
    name                = "${var.prefix}-vm"
    resource_group_name = data.azurerm_resource_group.sandbox.name
    location            = data.azurerm_resource_group.sandbox.location
    size                = var.vm_size
    admin_username      = var.vm_admin_username
    network_interface_ids = [
        azurerm_network_interface.main.id,
    ]

    admin_ssh_key {
        username   = var.vm_admin_username
        public_key = try(file(var.ssh_public_key), var.ssh_public_key)
    }

    os_disk {
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "Canonical"
        offer     = "0001-com-ubuntu-server-jammy"
        sku       = "22_04-lts-gen2"
        version   = "latest"
    }

    custom_data = base64encode(<<-EOT
#!/bin/bash
apt update -y
apt install -y apache2
systemctl start apache2
systemctl enable apache2
echo '<html><body><h1>Welcome to Azure DevOps Lab!</h1></body></html>' > /var/www/html/index.html
usermod -aG www-data ${var.vm_admin_username}
chown -R www-data:www-data /var/www/html
chmod -R 755 /var/www/html
# Allow azureuser to write to web root without sudo (needed for SCP deploy)
setfacl -R -m u:${var.vm_admin_username}:rwx /var/www/html 2>/dev/null || true
EOT
    )
}
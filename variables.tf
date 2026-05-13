variable "resource_group_name" {
    description = "name of the existing sandbox resource group"
    type = string
}

variable "location" {
    description = "Azure region for the resources"
    type = string
    default = "uksouth"
}

variable "vm_admin_username" {
    description = "admin username for linux vm"
    type = string
    default = "azureuser"
}

variable "ssh_public_key" {
    description = "SSH public key content for linux vm"
    type = string
}

variable "vm_size" {
    description = "size of the linux vm"
    type = string
    default = "Standard_B1s"
}

variable "prefix" {
    description = "prefix for the resources"
    type = string
    default = "devopslab"
}
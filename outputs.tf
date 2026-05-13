output "public_ip_address" {
    description = "Public IP address of the web server VM"
    value       = azurerm_public_ip.main.ip_address
}

output "ssh_connection_string" {
    description = "SSH connection string for the web server VM"
    value       = "ssh ${var.vm_admin_username}@${azurerm_public_ip.main.ip_address}"
}

output "website_url" {
    description = "URL to access the deployed website"
    value       = "http://${azurerm_public_ip.main.ip_address}"
}

output "resource_group_name" {
    description = "Name of the resource group"
    value       = data.azurerm_resource_group.sandbox.name
}
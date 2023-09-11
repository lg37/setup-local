output "pip_address" {
  value = data.azurerm_public_ip.pipdata.ip_address
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.mylinux.name
}
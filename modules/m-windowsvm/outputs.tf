output "pip_address" {
  value = data.azurerm_public_ip.pipdata.ip_address
}

output "vm_name" {
  value = azurerm_windows_virtual_machine.mywindows.name
}
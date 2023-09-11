output "vm_name_linux" {
  description = "Created linux VM name"
  value       = module.agentlinux.vm_name
}

output "vm_pip_linux" {
  description = "linux VM public IP"
  value       = module.agentlinux.pip_address
}
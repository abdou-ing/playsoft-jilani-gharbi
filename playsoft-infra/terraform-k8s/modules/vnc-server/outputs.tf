output "vm_ids" {
  value = proxmox_virtual_environment_vm.vm.vm_id
}

output "vm_ips" {
  value = proxmox_virtual_environment_vm.vm.ipv4_addresses
}

output "ipv4_addresses" {
  description = "All IPv4 addresses assigned to the VM"
  value       = flatten(proxmox_virtual_environment_vm.vm.ipv4_addresses)
}

output "primary_ipv4_address" {
  description = "Primary IPv4 address of the VM"
  value       = try([for ip in flatten(proxmox_virtual_environment_vm.vm.ipv4_addresses) : ip if ip != "127.0.0.1"][0], "")
}


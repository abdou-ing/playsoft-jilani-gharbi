output "vm_ids" {
  value = proxmox_virtual_environment_vm.windows_vm[*].vm_id
}

output "vm_names" {
  value = proxmox_virtual_environment_vm.windows_vm[*].name
}

output "ipv4_addresses" {
  value = proxmox_virtual_environment_vm.windows_vm[*].ipv4_addresses
}

output "primary_ipv4_addresses" {
  value = [
    for vm in proxmox_virtual_environment_vm.windows_vm : 
    try([for ip in flatten(vm.ipv4_addresses) : ip if ip != "127.0.0.1"][0], "")
  ]
}

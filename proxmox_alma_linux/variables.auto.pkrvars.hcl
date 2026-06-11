/*
* AlmaLinux 9 Proxmox Template - Variable Values
* ===========================================
*
* This file contains non-sensitive variable values for the Packer template.
* Sensitive values should be provided via seperate file.
*/

//----------------------------------------------------------------------
// Proxmox Connection Settings
//----------------------------------------------------------------------
proxmox_api_url         = "https://138.201.200.168:8006/api2/json"
proxmox_api_token_id    = "root@pam!packer"
proxmox_node            = "playsoft-proxmox"
proxmox_skip_tls_verify = true  // Change to false in production environments
proxmox_ip = "138.201.200.168"

//----------------------------------------------------------------------
// VM General Configuration
//----------------------------------------------------------------------
#vm_id   = "9001"  // Must be unique across the Proxmox cluster

//----------------------------------------------------------------------
// VM Hardware Configuration
//----------------------------------------------------------------------
vm_cores  = "2"
cpu_type  = "host"  // Uses host CPU features for best performance
vm_memory = "2048"  // In MB

//----------------------------------------------------------------------
// VM Storage Configuration
//----------------------------------------------------------------------
#iso_file         = "local:iso/AlmaLinux-9.7-x86_64-dvd.iso"
iso_storage_pool = "lvm-thin"
storage_pool     = "local"
disk_size        = "12G"
efi_storage_pool = "local"

//----------------------------------------------------------------------
// Network Configuration
//----------------------------------------------------------------------
network_bridge = "vmbr1"
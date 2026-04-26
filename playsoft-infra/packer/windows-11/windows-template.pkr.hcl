packer {
  required_plugins {
    proxmox = {
      source  = "github.com/hashicorp/proxmox"
      version = "~> 1.1"
    }
  }
}

variable "proxmox_url" {
  type    = string
}

variable "proxmox_username" {
  type    = string
}

variable "proxmox_token" {
  type      = string
  sensitive = true
}

variable "proxmox_node" {
  type    = string
}

variable "boot_iso" {
  type    = string
  default = "local:iso/Win11_25H2_English_x64.iso"
  # Or use Windows Server: "local:iso/windows-server-2022.iso"
}

source "proxmox-iso" "windows11" {
  # Proxmox Connection
  proxmox_url              = var.proxmox_url
  username                 = var.proxmox_username
  token                    = var.proxmox_token
  insecure_skip_tls_verify = true
  
  # VM Settings
  node                 = var.proxmox_node
  vm_name              = "windows11-student-vm"
  vm_id                = 2000
  template_description = "Windows 11 VM - User: student"
  cpu_type             = "host"
  machine              = "q35"
  bios                 = "ovmf"
  
  # ISO Configuration
  boot_iso {
    type         = "sata"
    index        = 0
    iso_file     = var.boot_iso
    iso_storage_pool = "local"
    unmount      = true
  }
  
  # Additional ISO (Autounattend and setup scripts)
  additional_iso_files {
    type         = "sata"
    index        = 4
    iso_storage_pool = "local"
    cd_files     = [
      "./http/Autounattend.xml",
      "./scripts/setup-winrm.ps1"
    ]
    cd_label     = "AUTOUNATTEND"
    unmount      = true
  }
  
  # OS Type
  os = "win11"
  
  # Hardware Configuration
  cores   = 2
  sockets = 1
  memory  = 4096
  
  network_adapters {
    model    = "e1000"
    bridge   = "vmbr0"
    firewall = false
  }
  
  disks {
    type         = "sata"
    disk_size    = "50G"
    storage_pool = "local"
    format       = "raw"
    discard      = true
  }
  
  # EFI / TPM configuration for Windows 11
  efi_config {
    efi_storage_pool  = "local"
    efi_type          = "4m"
    pre_enrolled_keys = true
  }

  tpm_config {
    tpm_storage_pool = "local"
    tpm_version      = "v2.0"
  }

  # Boot Configuration
  boot      = "order=sata0;sata1;net0"
  boot_wait = "5s"
  boot_command = [
    "<enter>"
  ]
  
  # Communicator (WinRM)
  communicator   = "winrm"
  winrm_username = "Administrator"
  winrm_password = "123456"
  winrm_timeout  = "4h"
  winrm_use_ssl  = false
  winrm_insecure = true
}

build {
  sources = ["source.proxmox-iso.windows11"]
  
  # Wait for system to be ready
  provisioner "powershell" {
    inline = [
      "Write-Host 'Waiting for system to be ready...'",
      "Start-Sleep -Seconds 30"
    ]
  }
  
  # Create student user with admin privileges
  provisioner "powershell" {
    script = "./scripts/create-user.ps1"
  }
  
  # Windows restart
  provisioner "windows-restart" {
    restart_timeout = "30m"
  }
  
  # Cleanup
  provisioner "powershell" {
    script = "./scripts/cleanup.ps1"
  }
  
}

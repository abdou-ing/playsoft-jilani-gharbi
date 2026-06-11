/*
* AlmaLinux 9 Proxmox Template - Variables
* ======================================
*
* This file contains all variable declarations used in the Packer template.
* Variable values are set in separate .auto.pkrvars.hcl files.
*
* Variable organization:
* 1. Proxmox Connection Variables
* 2. VM General Configuration Variables
* 3. VM Hardware Configuration Variables
* 4. VM Storage Configuration Variables
* 5. Network Configuration Variables
* 6. Security Variables
*/

//----------------------------------------------------------------------
// 1. Proxmox Connection Variables
//----------------------------------------------------------------------

variable "proxmox_api_url" {
  type        = string
  description = "URL for Proxmox VE API (e.g., https://proxmox.example.com:8006/api2/json)"
}

variable "proxmox_api_token_id" {
  type        = string
  description = "Token ID for Proxmox API authentication (e.g., root@pam!packer)"
}

variable "proxmox_api_token_secret" {
  type        = string
  sensitive   = true
  description = "Secret token for Proxmox API authentication"
}

variable "proxmox_node" {
  type        = string
  description = "Name of the Proxmox node where the VM will be created"
}

variable "proxmox_skip_tls_verify" {
  type        = bool
  default     = true
  description = "Skip TLS verification for Proxmox API (use false in production)"
}

//----------------------------------------------------------------------
// 2. VM General Configuration Variables
//----------------------------------------------------------------------

variable "env" {
  type        = string
  description = "The environment name"

  validation {
    condition     = contains(["dev", "stg", "prd"], var.env)
    error_message = "The environment must be one of: dev, stg, or prd."
  }
}

variable "version" {
  type        = string
  default     = "9"
  description = "AlmaLinux major version: 9 (uses AlmaLinux-9.7 ISO) or 10 (uses AlmaLinux-10 ISO)"

  validation {
    condition     = contains(["9", "10"], var.version)
    error_message = "Version must be 9 or 10."
  }
}

variable "vm_id" {
  type        = string
  description = "VM ID in Proxmox (must be unique, numeric)"
}

#variable "vm_name" {
#  type        = string
#  description = "Name of the VM template in Proxmox"
#}

//----------------------------------------------------------------------
// 3. VM Hardware Configuration Variables
//----------------------------------------------------------------------

variable "vm_cores" {
  type        = string
  description = "Number of CPU cores for the VM"
}

variable "cpu_type" {
  type        = string
  description = "CPU type for the VM (e.g., host, kvm64)"
}

variable "vm_memory" {
  type        = string
  description = "Amount of memory in MB for the VM"
}

//----------------------------------------------------------------------
// 4. VM Storage Configuration Variables
//----------------------------------------------------------------------

#variable "iso_file" {
#  type        = string
#  description = "Path to the ISO file in Proxmox storage (e.g., local:iso/AlmaLinux-9-latest-x86_64-minimal.iso)"
#}

variable "iso_storage_pool" {
  type        = string
  description = "Storage pool where the ISO is located"
}

variable "storage_pool" {
  type        = string
  description = "Storage pool for VM disk"
}

variable "disk_size" {
  type        = string
  description = "Size of the VM disk (e.g., 32G)"
}

variable "efi_storage_pool" {
  type        = string
  description = "Storage pool for EFI firmware"
}

//----------------------------------------------------------------------
// 5. Network Configuration Variables
//----------------------------------------------------------------------

variable "network_bridge" {
  type        = string
  description = "Network bridge for the VM (e.g., vmbr0)"
}

//----------------------------------------------------------------------
// 6. Security Variables
//----------------------------------------------------------------------

variable "vm_root_pw" {
  type        = string
  sensitive   = true
  description = "Root password for the VM (should be provided via environment variable)"
}


variable "management_lab_user" {
  type    = string
  default = "svcuseran"
  description = "User that the candidate will use for labs"
  validation {
    condition     = length(var.management_lab_user) > 0
    error_message = "The default lab user must not be empty."
  }
}

variable "custom_user_groups" {
  type    = string
  default = "restrictedgroup"
  description = "The group that will be able to use aws_cli."
}

variable "candidate_lab_user" {
  type    = string
  default = "student"
  description = "User that the candidate will use for labs"
  validation {
    condition     = length(var.candidate_lab_user) > 0
    error_message = "The default lab user must not be empty."
  }
}

variable "candidate_lab_user_password" {
  type    = string
  default = env("INSTALAB_USER_PASS")
  description = "User that the candidate will use for labs"
  validation {
    condition     = length(var.candidate_lab_user_password) >= 10
    error_message = "The default lab user password must not be empty."
  }
}

variable "proxmox_ip" {
  type    = string
}

variable "keep_releases" {
  type        = number
  default     = 1
  description = "The number of recent template to keep."
  validation {
    condition     = var.keep_releases > 0
    error_message = "The keep_releases variable must be a positive integer."
  }
}
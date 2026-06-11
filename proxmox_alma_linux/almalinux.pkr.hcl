/*
* AlmaLinux 9 Proxmox Template Builder
* ====================================
*
* This Packer configuration creates an AlmaLinux 9 VM template on Proxmox
* using a kickstart file hosted on GitHub to enable cross-network deployments.
*
* Author: Joshua Kunz
* Date: April 20, 2025
* Version: 1.1 - Updated for modern Packer syntax
*
* This configuration:
* - Uses GitHub-hosted kickstart files instead of the Packer HTTP server
* - Configures UEFI boot for modern system compatibility
* - Sets up Cloud-Init for VM templating
* - Includes proper cleanup for template preparation
*/

#packer {
#  required_version = ">= 1.8.0"
#  
#  required_plugins {
#    proxmox = {
#      version = "= 1.2.1"
#      source  = "github.com/hashicorp/proxmox"
#    }
#  }
#}

// Import variable declarations
locals {
  // Build timestamp for template versioning
  build_timestamp = formatdate("YYYYMMDDhhmmss", timestamp())

  // ISO file selected by version variable
  iso_file = var.version == "10" ? "local:iso/AlmaLinux-10.1-x86_64-dvd.iso" : "local:iso/AlmaLinux-9.7-x86_64-dvd.iso"

  // Template description with timestamp
  template_description = "AlmaLinux ${var.version} Minimal UEFI Template. Built ${local.build_timestamp}"

  // Tags updated by version
  tags = "alma${var.version};${var.env};lab_rhcsa${var.version}"

  // VM name based on version
  vm_name = "TPL-Lab-AlmaLinux${var.version}"
}

// Resource Definition for the VM Template
source "proxmox-iso" "almalinux" {
  /*
   * Proxmox Connection Settings
   * --------------------------
   * Configure authentication and connection parameters for Proxmox VE API
   */
  proxmox_url              = var.proxmox_api_url
  username                 = var.proxmox_api_token_id
  token                    = var.proxmox_api_token_secret
  insecure_skip_tls_verify = var.proxmox_skip_tls_verify

  /*
   * VM General Settings
   * ------------------
   * Basic VM identification and placement settings
   */
  node                  = var.proxmox_node
  vm_id                 = var.vm_id
  vm_name               = "${local.vm_name}-{{ timestamp}}"
  template_description  = local.template_description

  /*
   * VM OS Settings - Updated syntax
   * -------------
   * Installation media and boot settings
   */
  boot_iso {
    iso_file         = local.iso_file
    iso_storage_pool = var.iso_storage_pool
    unmount          = true
  }
  
  /*
   * VM System Settings
   * -----------------
   * Hardware and system configuration
   */
  qemu_agent = true

  // UEFI boot configuration
  bios = "ovmf"
  efi_config {
    efi_storage_pool  = var.efi_storage_pool
    efi_type          = "4m"
    pre_enrolled_keys = true
  }

  /*
   * VM Storage Settings
   * ------------------
   * Disk and storage configuration
   */
  scsi_controller = "virtio-scsi-pci"

  disks {
    disk_size           = var.disk_size
    storage_pool        = var.storage_pool
    type                = "scsi"    
    format              = "raw"
  }

  /*
   * VM Hardware Settings
   * -------------------
   * CPU and memory configuration
   */
  cores     = var.vm_cores
  cpu_type  = var.cpu_type
  memory    = var.vm_memory
  sockets   = "1"

  /*
   * VM Network Settings
   * ------------------
   * Network adapter configuration
   */
  network_adapters {
    model    = "virtio"
    bridge   = var.network_bridge
    firewall = "false"
  }

  /*
   * Boot and Provisioning Settings
   * -----------------------------
   * Boot command and connection settings for provisioning
   */
  // Boot command using Packer's HTTP server from dev.jokulab.ch
  boot_command = [
    "<up><wait>",
    "e<wait>",
    "<down><wait><down><wait>",
    "<end><wait>",
    " inst.text inst.ks=http://138.201.200.168/ks.cfg",
    "<wait>",
    "<f10><wait>"
  ]
  boot_wait = "10s"

  // HTTP server configuration - Packer will serve files from this directory
  http_directory = "files/kickstart"
  http_bind_address = "0.0.0.0"  // Bind to all interfaces so VM can access it
  http_port_min = 8000
  http_port_max = 8100







  /*
   * SSH Settings
   * -----------
   * SSH connection details for provisioning
   */
  ssh_username = "root"
  ssh_password = var.vm_root_pw
  ssh_timeout  = "30m"
  ssh_port             = 22
  #ssh_private_key_file    = "/home/abdou/.ssh/id_rsa"  # key to connect on the created VM 
  ssh_bastion_host       = var.proxmox_ip   #  proxmox IP
  ssh_bastion_port       = 22   
  ssh_bastion_username   = "root"
  #ssh_bastion_private_key_file = "/home/abdou/.ssh/id_ed25519"
  ssh_bastion_private_key_file = "/opt/keys/automation/id_ed25519"

  tags = local.tags
}

/*
 * Build Definition
 * --------------
 * Build process and provisioning steps
 */
build {
  name    = "almalinux-template"
  sources = ["source.proxmox-iso.almalinux"]

  provisioner "file" {
    source      = "../motivation/"
    destination = "/tmp/"
  }

  provisioner "file" {
    source      = "config.sh"
    destination = "/tmp/"
  }

  #provisioner "file" {
  #  source      = "../wazuh_files"
  #  destination = "/tmp/"
  #}

  provisioner "file" {
    source      = "./files/is_container"
    destination = "/tmp/"
  }

  provisioner "file" {
    source      = "./files/instalab_redhat.png"
    destination = "/tmp/"
  }

  provisioner "file" {
    source      = "./files/"
    destination = "/tmp/"
  }

  provisioner "file" {
    source      = "../../docker_images"
    destination = "/tmp/"
  }

  provisioner "shell" {

    environment_vars = [
      "MANAGEMENT_LAB_USER=${var.management_lab_user}",
      "CANDIDATE_LAB_USER=${var.candidate_lab_user}",
      "CANDIDATE_LAB_USER_PASSWORD=${var.candidate_lab_user_password}",
      "CUSTOM_USER_GROUPS=${var.custom_user_groups}"
    ]

    inline = [
      "chmod u+x /tmp/config.sh",
      "/tmp/config.sh"
    ]

    #inline = [
    #  "chmod u+x /tmp/config.sh",
    #  "sudo /tmp/config.sh --management_lab_user=${var.management_lab_user} --candidate_lab_user=${var.candidate_lab_user} --candidate_lab_user_password=${var.candidate_lab_user_password} --custom_user_groups=${var.custom_user_groups}"
    #]
  }

  /*
   * Provisioning Step 1: Copy Cloud-Init setup script
   * -----------------------------------------------
   * Transfer the setup script to the VM
   */
  provisioner "file" {
    source      = "scripts/setup-cloud-init.sh"
    destination = "/tmp/setup-cloud-init.sh"
  }

  /*
   * Provisioning Step 2: Execute Cloud-Init setup
   * -------------------------------------------
   * Configure Cloud-Init and prepare for templating
   */
  provisioner "shell" {
    inline = [
      "chmod +x /tmp/setup-cloud-init.sh",
      "/tmp/setup-cloud-init.sh"
    ]
  }

  /*
   * Provisioning Step 3: System cleanup
   * ---------------------------------
   * Clean up the system to prepare for templating
   */
  provisioner "shell" {
    script = "scripts/cleanup.sh"
  }

  

  /*
   * Post-Processor
   * ------------
   * Actions to perform after successful build
   */
  post-processor "shell-local" {
    inline = [
      "echo 'Build completed successfully!'",
      "echo 'Template Name: ${local.vm_name}'",
      "echo 'Template ID: ${var.vm_id}'"
    ]
  }

  post-processor "shell-local" {
    inline = [
      "ssh proxmox_server 'sudo bash /opt/cleanup-old-templates.sh ${local.vm_name} ${var.keep_releases}'"
    ]
  }
}
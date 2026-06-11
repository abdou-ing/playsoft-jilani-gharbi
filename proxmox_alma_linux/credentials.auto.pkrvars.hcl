/*
* AlmaLinux 9 Proxmox Template - Variable Values
* ===========================================
*
* This file contains sensitive variable values for the Packer template.
*/

//----------------------------------------------------------------------
// Proxmox Connection Settings - API Token
//----------------------------------------------------------------------
#proxmox_api_token_secret = "YOUR_PROXMOX_TOKEN"


//----------------------------------------------------------------------
// VM General Configuration - Root Password
// Should be hashed within ks.cfg
//----------------------------------------------------------------------
vm_root_pw = "My_PASSWORD_EXAMPLE" 
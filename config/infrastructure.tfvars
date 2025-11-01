# =============================================================================
# Proxmox Infrastructure Configuration - SAFE TO COMMIT
# =============================================================================
# This file contains non-sensitive infrastructure configuration
# It can be committed to Git for GitOps

# -----------------------------------------------------------------------------
# Proxmox Connection (without credentials)
# -----------------------------------------------------------------------------
proxmox_endpoint     = "https://your-proxmox.local:8006/api2/json"
proxmox_insecure     = true
proxmox_ssh_username = "root"

# -----------------------------------------------------------------------------
# Nodes and Template
# -----------------------------------------------------------------------------
proxmox_node          = "pve"
template_node         = "pve"
template_vm_id        = 9000
template_disk_size_gb = 20

# -----------------------------------------------------------------------------
# Storage
# -----------------------------------------------------------------------------
vm_datastore_id        = "local-lvm"
cloudinit_datastore_id = "local"

# -----------------------------------------------------------------------------
# Default VM Configuration
# -----------------------------------------------------------------------------
vm_description = "VM managed by Terraform"
vm_tags        = ["terraform", "managed"]

# CPU
vm_cpu_type  = "x86-64-v2-AES"
vm_cpu_cores = 6

# RAM
vm_memory_mb = 4096

# System disk
vm_disk_size_gb   = 20
vm_disk_interface = "scsi0"
vm_disk_iothread  = true
vm_disk_discard   = "on"

# Hardware
scsi_hardware = "virtio-scsi-single"

# QEMU Guest Agent
vm_agent_enabled_default = true
vm_agent_timeout         = "5m"

# -----------------------------------------------------------------------------
# Default Network
# -----------------------------------------------------------------------------
network_bridge   = "vmbr0"
network_vlan_tag = 0

# -----------------------------------------------------------------------------
# Default IP Configuration
# -----------------------------------------------------------------------------
vm_use_dhcp     = false
vm_ipv4_gateway = "192.168.1.1"
dns_servers     = ["1.1.1.1", "8.8.8.8"]

# -----------------------------------------------------------------------------
# Cloud-init
# -----------------------------------------------------------------------------
cloudinit_user = "ubuntu"

# -----------------------------------------------------------------------------
# Startup
# -----------------------------------------------------------------------------
vm_start_on_create = true
vm_start_on_boot   = true

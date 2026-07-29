# Infrastructure defaults - no secrets, safe to commit
# Credentials go in config/.env

# -----------------------------------------------------------------------------
# Proxmox Connection
# -----------------------------------------------------------------------------
proxmox_endpoint = "https://your-proxmox.local:8006/api2/json"
proxmox_insecure = true

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

# Ballooning: Proxmox can reclaim RAM down to vm_memory_floating_mb
vm_balloon_enabled = false
# vm_memory_floating_mb = 2048  # defaults to vm_memory_mb

# System disk
vm_disk_size_gb   = 20
vm_disk_interface = "scsi0"
vm_disk_iothread  = true
vm_disk_discard   = "on"

# Hardware
scsi_hardware = "virtio-scsi-single"

# QEMU Guest Agent
vm_agent_enabled_default = true
vm_agent_timeout         = "15m"

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
# Safety
# -----------------------------------------------------------------------------
# Blocks VM/disk removal (override per VM)
vm_protection = false

# -----------------------------------------------------------------------------
# Startup
# -----------------------------------------------------------------------------
vm_start_on_create = true
vm_start_on_boot   = true

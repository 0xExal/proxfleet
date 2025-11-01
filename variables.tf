# variables.tf
# Proxmox Connection
variable "proxmox_endpoint" {
  type    = string
  default = null
}

variable "proxmox_username" {
  type    = string
  default = null
}

variable "proxmox_password" {
  type      = string
  sensitive = true
  default   = null
}

variable "proxmox_insecure" {
  type    = bool
  default = false
}

variable "proxmox_ssh_username" {
  type    = string
  default = null
}

# Cible & source
variable "proxmox_node" {
  type = string
  # Node where to deploy the cloned VM
}

variable "template_node" {
  type = string
  # Node where the template is located
}

variable "template_vm_id" {
  type = number
  # VMID du template (qm template ...)
}

# Stockages
variable "vm_datastore_id" {
  type = string
  # ex: local-lvm (content: images)
}

variable "cloudinit_datastore_id" {
  type = string
  # ex: local-lvm
}

# Cloned VM
variable "vm_description" {
  description = "Default VM description (can be overridden per VM)"
  type        = string
  default     = "VM managed by Terraform (cloned from template)"
}

variable "vm_cpu_cores" {
  description = "Default number of CPU cores"
  type        = number
  default     = 2

  validation {
    condition     = var.vm_cpu_cores > 0 && var.vm_cpu_cores <= 128
    error_message = "Number of CPU cores must be between 1 and 128."
  }
}

variable "vm_cpu_type" {
  description = "Type de CPU (host, kvm64, x86-64-v2-AES, etc.)"
  type        = string
  default     = "x86-64-v2-AES"
}

variable "vm_memory_mb" {
  description = "Default RAM in MB"
  type        = number
  default     = 4096

  validation {
    condition     = var.vm_memory_mb >= 512
    error_message = "Memory must be at least 512 MB."
  }
}

variable "vm_disk_size_gb" {
  description = "System disk size in GB (must be >= template size)"
  type        = number
  default     = 30

  validation {
    condition     = var.vm_disk_size_gb > 0
    error_message = "Disk size must be greater than 0 GB."
  }
}

variable "template_disk_size_gb" {
  description = "Cloned template disk size in GiB. Used when skipping initial resize."
  type        = number
  default     = 30

  validation {
    condition     = var.template_disk_size_gb > 0
    error_message = "Template disk size must be greater than 0 GB."
  }
}

variable "vm_disk_interface" {
  description = "System disk interface (scsi0, virtio0, sata0, etc.)"
  type        = string
  default     = "scsi0"
}

variable "vm_disk_iothread" {
  description = "Enable iothread for better performance (requires SCSI/VirtIO)"
  type        = bool
  default     = true
}

variable "vm_disk_discard" {
  description = "Activer le discard/TRIM (on, ignore)"
  type        = string
  default     = "on"
}

variable "vm_skip_disk_resize_on_create" {
  description = "If true, Terraform won't try to resize the cloned disk (template size preserved)."
  type        = bool
  default     = false
}

# Network & DNS
variable "network_bridge" {
  type    = string
  default = "vmbr0"
}

variable "network_vlan_tag" {
  type    = number
  default = 0
  # 0 = no VLAN
}

variable "network_devices" {
  description = "Default network configuration (multiple interfaces if needed)."
  type = list(object({
    bridge  = string
    model   = optional(string)
    vlan_id = optional(number)
  }))
  default = []
}

variable "vm_use_dhcp" {
  type    = bool
  default = true
}

variable "vm_ipv4_address" {
  type    = string
  default = null
  # "192.168.1.50/24" si DHCP=false
}

variable "vm_ipv4_gateway" {
  type    = string
  default = null
}

variable "dns_servers" {
  type    = list(string)
  default = []
}

variable "vm_tags" {
  description = "Default tags applied to VMs"
  type        = list(string)
  default     = ["terraform", "managed"]
}

# Cloud-init user
variable "cloudinit_user" {
  description = "Username created by cloud-init"
  type        = string
  default     = "terraform"
}

variable "ssh_public_key" {
  description = "SSH public key for VM access (can be in .env)"
  type        = string
  default     = null
  sensitive   = true
}

variable "cloudinit_password_crypted" {
  description = "Encrypted password for cloud-init (generate with: mkpasswd -m sha-512)"
  type        = string
  default     = null
  sensitive   = true
}

variable "vm_agent_enabled_default" {
  description = "Enable QEMU Guest Agent at creation (recommended for reliable resize)."
  type        = bool
  default     = true
}

variable "vm_agent_timeout" {
  description = "Maximum wait time for QGA data (Terraform format: e.g. 5m, 30s)."
  type        = string
  default     = "5m"
}

variable "vm_start_on_create" {
  description = "Automatically start VM after creation"
  type        = bool
  default     = true
}

variable "vm_start_on_boot" {
  description = "Automatically start VM on Proxmox node boot"
  type        = bool
  default     = true
}

variable "scsi_hardware" {
  description = "SCSI controller type (virtio-scsi-pci, virtio-scsi-single, lsi, etc.)"
  type        = string
  default     = "virtio-scsi-single"
}

variable "vms" {
  description = "Map of VMs to create, indexed by logical identifier."
  type = map(object({
    # Identification
    vm_id       = number
    name        = optional(string)
    description = optional(string)
    tags        = optional(list(string))

    # Placement
    node_name      = optional(string)
    template_node  = optional(string)
    template_vm_id = optional(number)

    # Stockage
    vm_datastore_id        = optional(string)
    cloudinit_datastore_id = optional(string)

    # Ressources CPU/RAM
    vm_cpu_cores = optional(number)
    cpu_type     = optional(string)
    vm_memory_mb = optional(number)

    # System disk
    vm_disk_size_gb            = optional(number)
    skip_disk_resize_on_create = optional(bool)
    disk_interface             = optional(string)
    disk_iothread              = optional(bool)
    disk_discard               = optional(string)

    # Additional disks
    additional_disks = optional(list(object({
      size         = number
      datastore_id = optional(string)
      interface    = optional(string) # scsi1, scsi2, virtio1, etc.
      iothread     = optional(bool)
      discard      = optional(string)
    })))

    # Network
    network_bridge   = optional(string)
    network_vlan_tag = optional(number)
    network_devices = optional(list(object({
      bridge  = string
      model   = optional(string)
      vlan_id = optional(number)
    })))

    # IP Configuration
    vm_use_dhcp     = optional(bool)
    vm_ipv4_address = optional(string)
    vm_ipv4_gateway = optional(string)
    dns_servers     = optional(list(string))

    # Cloud-init
    cloudinit_user             = optional(string)
    ssh_public_key             = optional(string)
    cloudinit_password_crypted = optional(string)

    # QEMU Guest Agent
    agent_enabled = optional(bool)
    agent_timeout = optional(string)

    # Startup
    start_on_create = optional(bool)
    start_on_boot   = optional(bool)

    # Hardware
    scsi_hardware = optional(string)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.vms : v.vm_id > 100 && v.vm_id < 999999999
    ])
    error_message = "VM IDs must be between 100 and 999999999."
  }
}

# ProxFleet

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Terraform](https://img.shields.io/badge/Terraform-%3E%3D1.5.0-623CE4?logo=terraform)](https://www.terraform.io/)

**Terraform module for managing Proxmox VE virtual machines**

> **Note**: Initially a personal project, now open-sourced. Some parts were AI-assisted and are rigorously human-reviewed.


---

## Overview

ProxFleet simplifies VM provisioning on Proxmox VE using Terraform. It separates code, configuration, and secrets for clean GitOps workflows.

## Features

- Clone VMs from Proxmox templates
- Multi-disk and multi-NIC support
- VLAN tagging
- Cloud-init integration
- QEMU Guest Agent support for reliable disk resizing
- Automatic cloud-init cleanup
- Input validation

---

## Quick Start

### Prerequisites

- Terraform >= 1.5.0
- Proxmox VE 7.x or 8.x
- VM template with cloud-init and qemu-guest-agent
- SSH access to Proxmox node

### Setup

```bash
# Clone
git clone https://github.com/0xExal/proxfleet.git
cd proxfleet

# Setup configs
make setup

# Edit credentials
vim config/.env
vim config/infrastructure.tfvars
vim config/vms.tfvars

# Deploy
make init
make plan
make apply
```

### Commands

```bash
make help      # Show commands
make plan      # Preview changes
make apply     # Apply changes
make destroy   # Destroy VMs
make output    # Show outputs
```

---

## Configuration

### File Structure

```
config/
├── .env                      # Credentials (never commit)
├── infrastructure.tfvars     # Proxmox config (safe to commit)
└── vms.tfvars               # VM definitions (safe to commit)
```

### Example VM Definition

```hcl
vms = {
  web-server = {
    vm_id           = 100
    vm_cpu_cores    = 2
    vm_memory_mb    = 4096
    vm_disk_size_gb = 50

    vm_use_dhcp     = false
    vm_ipv4_address = "192.168.1.10/24"
    vm_ipv4_gateway = "192.168.1.1"
  }
}
```

See [docs/EXAMPLES.md](docs/EXAMPLES.md) for more examples.

---

## Troubleshooting

### Disk resize fails

Install QEMU Guest Agent in your template:
```bash
apt-get install qemu-guest-agent
systemctl enable qemu-guest-agent
```

Or skip resize:
```hcl
skip_disk_resize_on_create = true
```

### Cloud-init disk exists error

The module automatically cleans orphaned disks. If it still fails:
```bash
ssh root@proxmox-node
pvesm free local:vm-<VMID>-cloudinit
```

---

## Creating a Template

Use the helper script in your VM:
```bash
sudo ./scripts/setup-template.sh
shutdown -h now
```

Then on Proxmox:
```bash
qm template <VMID>
```


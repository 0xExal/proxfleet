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
- Optional RAM ballooning (global or per-VM)
- QEMU Guest Agent support for reliable disk resizing
- Input validation
- Per-VM override of any global default

---

## Quick Start

### Prerequisites

- Terraform >= 1.5.0
- Proxmox VE 7.x or 8.x
- VM template with cloud-init and qemu-guest-agent

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

### Cloud-init changes are not re-applied

To avoid VM restarts, `initialization` is in `ignore_changes`. **Changing IP, DNS, user, password or SSH key after creation has no effect.** To re-apply, recreate the VM:

```bash
terraform apply -replace='proxmox_virtual_environment_vm.vm["<vm-key>"]' \
  -var-file=config/infrastructure.tfvars -var-file=config/vms.tfvars
```

See [docs/EXAMPLES.md](docs/EXAMPLES.md) for more examples.

---

## Remote State

State is local by default (`terraform.tfstate`). It contains sensitive data and losing it orphans your VMs. For team use, enable the backend example in `versions.tf` and run `terraform init -migrate-state`.

---

## Troubleshooting

### Disk resize fails or times out

**Timeout error** (`qemu-img resize ... failed: got timeout`):
```hcl
# Increase timeout for large disks in infrastructure.tfvars
vm_agent_timeout = "15m"  # or "20m" for very large disks (>500GB)
```

**Guest agent not installed**:
```bash
apt-get install qemu-guest-agent
systemctl enable qemu-guest-agent
```

**Skip resize entirely** (use template size):
```hcl
skip_disk_resize_on_create = true
```

### Cloud-init disk exists error

Manually clean orphaned disks on the Proxmox node:
```bash
ssh root@proxmox-node
pvesm free <datastore>:vm-<VMID>-cloudinit
# Example: pvesm free local-lvm:vm-100-cloudinit
```

Then run `terraform apply` again.

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


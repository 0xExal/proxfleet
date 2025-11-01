# ProxFleet Scripts

Helper scripts for ProxFleet operations.

## Available Scripts

### setup-template.sh

Prepares a VM to be converted into a Proxmox template.

**Usage:**
```bash
# Run inside the VM you want to convert to a template
sudo ./scripts/setup-template.sh
```

**What it does:**
- Installs cloud-init and QEMU Guest Agent
- Configures cloud-init for Proxmox
- Cleans machine data (machine-id, logs, etc.)

**After running:**
```bash
# 1. Shutdown the VM
shutdown -h now

# 2. On Proxmox host, convert to template
qm template <VMID>
```

---

### validate-config.sh

Validates your configuration files before deployment.

**Usage:**
```bash
./scripts/validate-config.sh
```

**Checks:**
- Required files exist
- No placeholder values (like "your-proxmox.local")
- No duplicate VM IDs
- Terraform is installed

**Exit codes:**
- `0` - All checks passed
- `1` - Errors found

---

## Requirements

- Bash
- Terraform (for validate-config.sh)
- jq (for validate-config.sh)

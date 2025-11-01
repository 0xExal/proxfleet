# outputs.tf
# Essential outputs for ProxFleet

# ============================================================================
# Virtual Machines Information
# ============================================================================

output "vms" {
  description = "List of created VMs with their main information"
  value = {
    for key, vm in proxmox_virtual_environment_vm.vm :
    key => {
      id     = vm.vm_id
      name   = vm.name
      node   = vm.node_name
      ip     = try([for ip in vm.ipv4_addresses : ip if !startswith(ip, "127.")][0], "Pending...")
      cpu    = vm.cpu[0].cores
      memory = "${vm.memory[0].dedicated / 1024} GB"
      status = vm.started ? "Running" : "Stopped"
    }
  }
}

# ============================================================================
# Quick Access
# ============================================================================

output "ips" {
  description = "VM IP addresses"
  value = {
    for key, vm in proxmox_virtual_environment_vm.vm :
    key => try(
      [for ip in vm.ipv4_addresses : ip if !startswith(ip, "127.")][0],
      "Pending..."
    )
  }
}

output "ssh" {
  description = "SSH connection commands for VMs"
  value = {
    for key, vm in proxmox_virtual_environment_vm.vm :
    key => try(
      "ssh ${local.vm_configs[key].cloudinit_user}@${[for ip in vm.ipv4_addresses : ip if !startswith(ip, "127.")][0]}",
      "IP not available"
    )
  }
}

# ============================================================================
# Deployment Summary
# ============================================================================

output "summary" {
  description = "Deployment summary"
  value = {
    total_vms       = length(proxmox_virtual_environment_vm.vm)
    total_cpu_cores = sum([for vm in proxmox_virtual_environment_vm.vm : vm.cpu[0].cores])
    total_memory_gb = sum([for vm in proxmox_virtual_environment_vm.vm : vm.memory[0].dedicated]) / 1024
    all_running     = alltrue([for vm in proxmox_virtual_environment_vm.vm : vm.started])
  }
}

# ============================================================================
# Utility Files
# ============================================================================

output "hosts_file" {
  description = "/etc/hosts entries (copy-paste ready)"
  value = join("\n", [
    for key, vm in proxmox_virtual_environment_vm.vm :
    try(
      "${[for ip in vm.ipv4_addresses : ip if !startswith(ip, "127.")][0]}\t${vm.name}",
      "# ${vm.name} - IP not available"
    )
  ])
}

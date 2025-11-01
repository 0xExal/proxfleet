locals {
  env_file_path = "config/.env"
  env_lines     = fileexists(local.env_file_path) ? split("\n", file(local.env_file_path)) : []

  env_pairs = [
    for line in local.env_lines : {
      key       = trimspace(split("=", line)[0])
      raw_value = trimspace(join("=", slice(split("=", line), 1, length(split("=", line)))))
    }
    if length(trimspace(line)) > 0
    && !startswith(trimspace(line), "#")
    && length(split("=", line)) >= 2
  ]

  env_vars = {
    for pair in local.env_pairs :
    pair.key => (
      length(pair.raw_value) >= 2
      && (
        (startswith(pair.raw_value, "\"") && endswith(pair.raw_value, "\""))
        || (startswith(pair.raw_value, "'") && endswith(pair.raw_value, "'"))
      )
      ? substr(pair.raw_value, 1, length(pair.raw_value) - 2)
      : pair.raw_value
    )
  }

  proxmox_username_effective = try(
    coalesce(
      try(var.proxmox_username, null),
      lookup(local.env_vars, "PROXMOX_USERNAME", null)
    ),
    null
  )

  proxmox_password_effective = try(
    coalesce(
      var.proxmox_password,
      lookup(local.env_vars, "PROXMOX_PASSWORD", null)
    ),
    null
  )

  ssh_public_key_effective = try(
    coalesce(
      var.ssh_public_key,
      lookup(local.env_vars, "SSH_PUBLIC_KEY", null)
    ),
    null
  )

  cloudinit_password_effective = try(
    coalesce(
      var.cloudinit_password_crypted,
      lookup(local.env_vars, "CLOUDINIT_PASSWORD_CRYPTED", null)
    ),
    null
  )

  proxmox_endpoint_effective = try(
    coalesce(
      try(var.proxmox_endpoint, null),
      lookup(local.env_vars, "PROXMOX_ENDPOINT", null)
    ),
    null
  )

  proxmox_ssh_username_effective = try(
    coalesce(
      try(var.proxmox_ssh_username, null),
      lookup(local.env_vars, "PROXMOX_SSH_USERNAME", null),
      "root"
    ),
    "root"
  )

  default_network_devices = (
    length(var.network_devices) > 0
    ? [
      for dev in var.network_devices : {
        bridge  = lookup(dev, "bridge", var.network_bridge)
        model   = lookup(dev, "model", "virtio")
        vlan_id = lookup(dev, "vlan_id", var.network_vlan_tag)
      }
    ]
    : [
      {
        bridge  = var.network_bridge
        model   = "virtio"
        vlan_id = var.network_vlan_tag
      }
    ]
  )

  vm_configs = {
    for vm_key, vm in var.vms : vm_key => {
      vm_id                      = vm.vm_id
      name                       = coalesce(vm.name, vm_key)
      description                = coalesce(vm.description, var.vm_description)
      tags                       = coalesce(vm.tags, var.vm_tags)
      node_name                  = coalesce(vm.node_name, var.proxmox_node)
      template_node              = coalesce(vm.template_node, var.template_node)
      template_vm_id             = coalesce(vm.template_vm_id, var.template_vm_id)
      vm_datastore_id            = coalesce(vm.vm_datastore_id, var.vm_datastore_id)
      cloudinit_datastore_id     = coalesce(vm.cloudinit_datastore_id, var.cloudinit_datastore_id)
      vm_cpu_cores               = coalesce(vm.vm_cpu_cores, var.vm_cpu_cores)
      vm_memory_mb               = coalesce(vm.vm_memory_mb, var.vm_memory_mb)
      vm_disk_size_gb            = coalesce(vm.vm_disk_size_gb, var.vm_disk_size_gb)
      skip_disk_resize_on_create = coalesce(vm.skip_disk_resize_on_create, var.vm_skip_disk_resize_on_create)
      disk_size_to_apply = (
        coalesce(vm.skip_disk_resize_on_create, var.vm_skip_disk_resize_on_create)
        ? var.template_disk_size_gb
        : coalesce(vm.vm_disk_size_gb, var.vm_disk_size_gb)
      )
      cpu_type         = coalesce(vm.cpu_type, var.vm_cpu_type)
      disk_interface   = coalesce(vm.disk_interface, var.vm_disk_interface)
      disk_iothread    = coalesce(vm.disk_iothread, var.vm_disk_iothread)
      disk_discard     = coalesce(vm.disk_discard, var.vm_disk_discard)
      network_bridge   = coalesce(vm.network_bridge, var.network_bridge)
      network_vlan_tag = coalesce(vm.network_vlan_tag, var.network_vlan_tag)
      scsi_hardware    = coalesce(vm.scsi_hardware, var.scsi_hardware)
      additional_disks = coalesce(vm.additional_disks, [])

      network_devices = (
        length(coalesce(try(vm.network_devices, []), [])) > 0
        ? [
          for dev in coalesce(try(vm.network_devices, []), []) : {
            bridge = try(dev.bridge, null) != null ? dev.bridge : (
              try(vm.network_bridge, null) != null ? vm.network_bridge : var.network_bridge
            )
            model = coalesce(try(dev.model, null), "virtio")
            vlan_id = try(dev.vlan_id, null) != null ? dev.vlan_id : (
              try(vm.network_vlan_tag, null) != null ? vm.network_vlan_tag : var.network_vlan_tag
            )
          }
        ]
        : [
          for idx, dev in local.default_network_devices : {
            bridge  = idx == 0 && try(vm.network_bridge, null) != null ? vm.network_bridge : dev.bridge
            model   = dev.model
            vlan_id = idx == 0 && try(vm.network_vlan_tag, null) != null ? vm.network_vlan_tag : dev.vlan_id
          }
        ]
      )

      vm_use_dhcp        = coalesce(vm.vm_use_dhcp, var.vm_use_dhcp)
      vm_ipv4_address    = vm.vm_ipv4_address != null ? vm.vm_ipv4_address : var.vm_ipv4_address
      vm_ipv4_gateway    = vm.vm_ipv4_gateway != null ? vm.vm_ipv4_gateway : var.vm_ipv4_gateway
      dns_servers        = coalesce(vm.dns_servers, var.dns_servers)
      cloudinit_user     = coalesce(vm.cloudinit_user, var.cloudinit_user)
      ssh_public_key     = vm.ssh_public_key != null ? vm.ssh_public_key : local.ssh_public_key_effective
      cloudinit_password = vm.cloudinit_password_crypted != null ? vm.cloudinit_password_crypted : local.cloudinit_password_effective

      agent_enabled   = coalesce(try(vm.agent_enabled, null), var.vm_agent_enabled_default)
      agent_timeout   = coalesce(try(vm.agent_timeout, null), var.vm_agent_timeout)
      start_on_create = coalesce(try(vm.start_on_create, null), var.vm_start_on_create)
      start_on_boot   = coalesce(try(vm.start_on_boot, null), var.vm_start_on_boot)
    }
  }

  ssh_authorized_keys = {
    for vm_key, cfg in local.vm_configs :
    vm_key => (
      can(trimspace(cfg.ssh_public_key)) && trimspace(cfg.ssh_public_key) != ""
      ? [trimspace(cfg.ssh_public_key)]
      : []
    )
  }

  cloudinit_passwords = {
    for vm_key, cfg in local.vm_configs :
    vm_key => (
      can(trimspace(cfg.cloudinit_password)) && trimspace(cfg.cloudinit_password) != ""
      ? trimspace(cfg.cloudinit_password)
      : null
    )
  }
}

provider "proxmox" {
  endpoint = local.proxmox_endpoint_effective
  username = local.proxmox_username_effective
  password = local.proxmox_password_effective
  insecure = var.proxmox_insecure

  ssh {
    agent    = true
    username = local.proxmox_ssh_username_effective
  }
}

# Cleanup orphaned cloud-init disk if VM doesn't exist
# Improvement: more robust error handling and logging
resource "null_resource" "ci_cleanup" {
  for_each = local.vm_configs

  triggers = {
    run_at = timestamp()
    vmid   = each.value.vm_id
  }

  provisioner "local-exec" {
    command = <<-EOC
      set -eo pipefail

      SSH="ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=10"
      SSH_USER="${local.proxmox_ssh_username_effective}"
      SSH_HOST="${trimsuffix(trimprefix(local.proxmox_endpoint_effective, "https://"), ":8006/api2/json")}"
      VMID="${each.value.vm_id}"
      DATASTORE="${each.value.cloudinit_datastore_id}"

      echo "Checking cloud-init cleanup for VM $VMID..."

      # Check if VM exists
      if ! $SSH $SSH_USER@$SSH_HOST "qm status $VMID >/dev/null 2>&1"; then
        echo "VM $VMID doesn't exist, cleaning up orphaned cloud-init files..."

        # Attempt cleanup via pvesm (clean method)
        $SSH $SSH_USER@$SSH_HOST "pvesm free $DATASTORE:images/$VMID/vm-$VMID-cloudinit.qcow2 2>/dev/null || echo 'pvesm free failed (normal if already cleaned)'"

        # Cleanup residual files (backup)
        $SSH $SSH_USER@$SSH_HOST "rm -f /var/lib/vz/images/$VMID/vm-$VMID-cloudinit.qcow2 2>/dev/null || true"
        $SSH $SSH_USER@$SSH_HOST "rmdir /var/lib/vz/images/$VMID 2>/dev/null || true"

        # Alternative attempt for certain datastores
        $SSH $SSH_USER@$SSH_HOST "pvesm free $DATASTORE:vm-$VMID-cloudinit 2>/dev/null || true"

        echo "Cloud-init cleanup completed for VM $VMID"
      else
        echo "VM $VMID exists, no cleanup needed"
      fi
    EOC

    on_failure = continue
  }
}

resource "proxmox_virtual_environment_vm" "vm" {
  for_each = local.vm_configs

  node_name   = each.value.node_name
  name        = each.value.name
  description = each.value.description
  vm_id       = each.value.vm_id
  tags        = each.value.tags

  clone {
    node_name = each.value.template_node
    vm_id     = each.value.template_vm_id
  }

  # Don't force BIOS, keep the template's BIOS setting
  # bios = "seabios"

  operating_system { type = "l26" }

  cpu {
    cores   = each.value.vm_cpu_cores
    sockets = 1
    type    = each.value.cpu_type
  }

  memory { dedicated = each.value.vm_memory_mb }

  scsi_hardware = each.value.scsi_hardware

  # System disk (cloned from template)
  disk {
    datastore_id = each.value.vm_datastore_id
    interface    = each.value.disk_interface
    size         = each.value.disk_size_to_apply
    discard      = each.value.disk_discard
    iothread     = each.value.disk_iothread
  }

  # Additional data disks
  dynamic "disk" {
    for_each = each.value.additional_disks
    content {
      datastore_id = coalesce(disk.value.datastore_id, each.value.vm_datastore_id)
      interface    = coalesce(disk.value.interface, "scsi${disk.key + 1}")
      size         = disk.value.size
      discard      = coalesce(disk.value.discard, each.value.disk_discard)
      iothread     = coalesce(disk.value.iothread, each.value.disk_iothread)
      file_format  = "raw"
    }
  }

  dynamic "network_device" {
    for_each = each.value.network_devices
    content {
      bridge  = network_device.value.bridge
      model   = network_device.value.model
      vlan_id = network_device.value.vlan_id
    }
  }

  boot_order = ["scsi0", "net0"]

  initialization {
    datastore_id = each.value.cloudinit_datastore_id

    ip_config {
      ipv4 {
        address = each.value.vm_use_dhcp ? "dhcp" : each.value.vm_ipv4_address
        gateway = each.value.vm_use_dhcp ? null : each.value.vm_ipv4_gateway
      }
    }

    dns { servers = each.value.dns_servers }

    user_account {
      username = each.value.cloudinit_user
      password = lookup(local.cloudinit_passwords, each.key)
      keys     = lookup(local.ssh_authorized_keys, each.key)
    }
  }

  # QEMU Guest Agent (recommended for reliable disk resizing)
  agent {
    enabled = each.value.agent_enabled
    timeout = each.value.agent_timeout
  }

  started = each.value.start_on_create
  on_boot = each.value.start_on_boot

  lifecycle {
    # Validations
    precondition {
      condition     = each.value.vm_disk_size_gb >= var.template_disk_size_gb
      error_message = "VM disk size (${each.value.vm_disk_size_gb}GB) must be >= template size (${var.template_disk_size_gb}GB) for ${each.key}."
    }

    precondition {
      condition     = can(regex("^[a-zA-Z0-9-_]+$", each.value.name))
      error_message = "VM name '${each.value.name}' must contain only letters, numbers, hyphens and underscores."
    }

    precondition {
      condition     = each.value.vm_memory_mb >= 512
      error_message = "Memory must be at least 512 MB for ${each.key}."
    }

    precondition {
      condition     = each.value.vm_cpu_cores > 0 && each.value.vm_cpu_cores <= 128
      error_message = "Number of CPU cores must be between 1 and 128 for ${each.key}."
    }

    # Ignore changes to cloud-init password after creation
    ignore_changes = [
      initialization[0].user_account[0].password,
    ]
  }

  depends_on = [null_resource.ci_cleanup]
}

# Resource to manage disk resizing reliably
resource "null_resource" "disk_resize_wait" {
  for_each = {
    for vm_key, cfg in local.vm_configs : vm_key => cfg
    if !cfg.skip_disk_resize_on_create && cfg.vm_disk_size_gb > var.template_disk_size_gb
  }

  triggers = {
    vm_id        = each.value.vm_id
    disk_size    = each.value.vm_disk_size_gb
    node_name    = each.value.node_name
    proxmox_host = trimsuffix(trimprefix(local.proxmox_endpoint_effective, "https://"), ":8006/api2/json")
    ssh_user     = local.proxmox_ssh_username_effective
  }

  # Wait for VM to be ready and qemu-guest-agent to be available
  provisioner "local-exec" {
    command = <<-EOC
      set -eo pipefail

      SSH="ssh -o BatchMode=yes -o StrictHostKeyChecking=no ${self.triggers.ssh_user}@${self.triggers.proxmox_host}"
      VMID=${self.triggers.vm_id}
      MAX_WAIT=300
      ELAPSED=0

      echo "Waiting for VM $VMID to be ready for resize..."

      # Wait for VM to start
      while [ $ELAPSED -lt $MAX_WAIT ]; do
        STATUS=$($SSH "qm status $VMID" | grep -oP '(?<=status: )\w+' || echo "unknown")
        if [ "$STATUS" = "running" ]; then
          echo "VM $VMID is started"
          break
        fi
        echo "VM status: $STATUS, waiting... ($ELAPSED/$MAX_WAIT s)"
        sleep 5
        ELAPSED=$((ELAPSED + 5))
      done

      # Wait for qemu-guest-agent to respond (if enabled)
      if ${each.value.agent_enabled}; then
        echo "Waiting for qemu-guest-agent..."
        ELAPSED=0
        while [ $ELAPSED -lt $MAX_WAIT ]; do
          if $SSH "qm agent $VMID ping 2>/dev/null" >/dev/null 2>&1; then
            echo "qemu-guest-agent responding for VM $VMID"
            sleep 5  # Additional wait for stability
            break
          fi
          echo "qemu-guest-agent not responding yet... ($ELAPSED/$MAX_WAIT s)"
          sleep 10
          ELAPSED=$((ELAPSED + 10))
        done
      else
        echo "Guest agent disabled, waiting 30s for stabilization..."
        sleep 30
      fi

      echo "VM $VMID ready for operations"
    EOC
  }

  depends_on = [proxmox_virtual_environment_vm.vm]
}

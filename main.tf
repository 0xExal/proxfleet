locals {
  env_file_path = "${path.module}/config/.env"
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

  default_network_devices = (
    length(var.network_devices) > 0
    ? [
      for dev in var.network_devices : {
        bridge  = dev.bridge
        model   = coalesce(dev.model, "virtio")
        vlan_id = coalesce(dev.vlan_id, var.network_vlan_tag)
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
      scsi_hardware    = coalesce(vm.scsi_hardware, var.scsi_hardware)
      additional_disks = coalesce(vm.additional_disks, [])

      network_devices = (
        length(coalesce(vm.network_devices, [])) > 0
        ? [
          for dev in coalesce(vm.network_devices, []) : {
            bridge  = dev.bridge
            model   = coalesce(dev.model, "virtio")
            vlan_id = coalesce(dev.vlan_id, vm.network_vlan_tag, var.network_vlan_tag)
          }
        ]
        : [
          for idx, dev in local.default_network_devices : {
            bridge  = idx == 0 && vm.network_bridge != null ? vm.network_bridge : dev.bridge
            model   = dev.model
            vlan_id = idx == 0 && vm.network_vlan_tag != null ? vm.network_vlan_tag : dev.vlan_id
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

      agent_enabled   = coalesce(vm.agent_enabled, var.vm_agent_enabled_default)
      agent_timeout   = coalesce(vm.agent_timeout, var.vm_agent_timeout)
      start_on_create = coalesce(vm.start_on_create, var.vm_start_on_create)
      start_on_boot   = coalesce(vm.start_on_boot, var.vm_start_on_boot)
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
}

resource "proxmox_virtual_environment_vm" "vm" {
  for_each = local.vm_configs

  node_name   = each.value.node_name
  name        = each.value.name
  description = each.value.description
  vm_id       = each.value.vm_id
  tags        = sort(each.value.tags)

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

  memory {
    dedicated = each.value.vm_memory_mb
    floating  = 0
  }

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
      vlan_id = network_device.value.vlan_id > 0 ? network_device.value.vlan_id : null
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

    precondition {
      condition     = each.value.vm_use_dhcp || each.value.vm_ipv4_address != null
      error_message = "vm_ipv4_address is required when vm_use_dhcp = false for ${each.key}."
    }

    ignore_changes = [
      initialization,
      started,
    ]
  }
}

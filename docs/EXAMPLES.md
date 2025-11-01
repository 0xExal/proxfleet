# Configuration Examples

## Example 1: Simple VM with DHCP

```hcl
vms = {
  web-server = {
    vm_id           = 201
    name            = "web-01"
    vm_cpu_cores    = 2
    vm_memory_mb    = 4096
    vm_disk_size_gb = 30
    vm_use_dhcp     = true
  }
}
```

## Example 2: VM with Static IP and VLAN

```hcl
vms = {
  database = {
    vm_id       = 301
    name        = "db-prod-01"
    vm_cpu_cores = 8
    vm_memory_mb = 16384
    vm_disk_size_gb = 100

    network_devices = [{
      bridge  = "vmbr1"
      vlan_id = 100
    }]

    vm_use_dhcp     = false
    vm_ipv4_address = "10.0.100.50/24"
    vm_ipv4_gateway = "10.0.100.1"
    dns_servers     = ["10.0.0.1", "1.1.1.1"]
  }
}
```

## Example 3: VM with Additional Disks

```hcl
vms = {
  storage-server = {
    vm_id           = 401
    name            = "storage-01"
    vm_cpu_cores    = 4
    vm_memory_mb    = 8192
    vm_disk_size_gb = 50  # System disk

    # Additional data disks
    additional_disks = [
      {
        size      = 500  # 500 GB for /data
        interface = "scsi1"
      },
      {
        size      = 200  # 200 GB for /backup
        interface = "scsi2"
      }
    ]

    vm_ipv4_address = "10.0.0.60/24"
    vm_ipv4_gateway = "10.0.0.1"
  }
}
```

## Example 4: Kubernetes Cluster (Multi-VMs)

```hcl
vms = {
  k8s-master-01 = {
    vm_id           = 501
    name            = "k8s-master-01"
    tags            = ["kubernetes", "master", "prod"]
    vm_cpu_cores    = 4
    vm_memory_mb    = 8192
    vm_disk_size_gb = 50
    vm_ipv4_address = "10.0.20.10/24"
    vm_ipv4_gateway = "10.0.20.1"
  }

  k8s-worker-01 = {
    vm_id           = 511
    name            = "k8s-worker-01"
    tags            = ["kubernetes", "worker", "prod"]
    vm_cpu_cores    = 8
    vm_memory_mb    = 16384
    vm_disk_size_gb = 50
    additional_disks = [
      { size = 200, interface = "scsi1" }  # For containers
    ]
    vm_ipv4_address = "10.0.20.20/24"
    vm_ipv4_gateway = "10.0.20.1"
  }

  k8s-worker-02 = {
    vm_id           = 512
    name            = "k8s-worker-02"
    tags            = ["kubernetes", "worker", "prod"]
    vm_cpu_cores    = 8
    vm_memory_mb    = 16384
    vm_disk_size_gb = 50
    additional_disks = [
      { size = 200, interface = "scsi1" }
    ]
    vm_ipv4_address = "10.0.20.21/24"
    vm_ipv4_gateway = "10.0.20.1"
  }
}
```

## Example 5: Firewall with Multiple Network Interfaces

```hcl
vms = {
  firewall = {
    vm_id        = 601
    name         = "pfsense-01"
    tags         = ["firewall", "security"]
    vm_cpu_cores = 4
    vm_memory_mb = 4096

    # 3 network interfaces
    network_devices = [
      { bridge = "vmbr0" },                # WAN
      { bridge = "vmbr1", vlan_id = 10 },  # LAN
      { bridge = "vmbr1", vlan_id = 20 },  # DMZ
    ]

    vm_use_dhcp = true  # On WAN only
  }
}
```

## Example 6: Development Environment

```hcl
vms = {
  dev-web = {
    vm_id           = 701
    name            = "dev-web-01"
    tags            = ["development", "web"]
    vm_cpu_cores    = 2
    vm_memory_mb    = 2048
    vm_disk_size_gb = 30
    vm_ipv4_address = "10.0.30.10/24"
    vm_ipv4_gateway = "10.0.30.1"
  }

  dev-db = {
    vm_id           = 702
    name            = "dev-db-01"
    tags            = ["development", "database"]
    vm_cpu_cores    = 4
    vm_memory_mb    = 8192
    vm_disk_size_gb = 50
    additional_disks = [
      { size = 100, interface = "scsi1" }  # Database storage
    ]
    vm_ipv4_address = "10.0.30.20/24"
    vm_ipv4_gateway = "10.0.30.1"
  }
}
```

---

See [README.md](../README.md) for more details on available variables.

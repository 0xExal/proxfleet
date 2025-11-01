# =============================================================================
# VMs Public Configuration - SAFE TO COMMIT
# =============================================================================
# This file contains only VM definitions (no secrets)
# It can be committed to Git for GitOps

# =============================================================================
# VMs to create
# =============================================================================

vms = {
  # ---------------------------------------------------------------------------
  # web-server - Example web server
  # ---------------------------------------------------------------------------
  web-server = {
    vm_id       = 100
    name        = "web-server"
    description = "Web application server"
    tags        = ["web", "production"]

    # Resources
    vm_cpu_type     = "x86-64-v2-AES"
    vm_cpu_cores    = 2
    vm_memory_mb    = 4096
    vm_disk_size_gb = 50

    # Network
    vm_use_dhcp     = false
    vm_ipv4_address = "192.168.1.10/24"
    vm_ipv4_gateway = "192.168.1.1"
    dns_servers     = ["1.1.1.1", "8.8.8.8"]
  }

  # ---------------------------------------------------------------------------
  # database - Database server with additional disk
  # ---------------------------------------------------------------------------
  database = {
    vm_id       = 101
    name        = "database"
    description = "PostgreSQL database server"
    tags        = ["database", "production"]

    # Resources
    vm_cpu_type     = "x86-64-v2-AES"
    vm_cpu_cores    = 4
    vm_memory_mb    = 8192
    vm_disk_size_gb = 100

    # Network
    vm_use_dhcp     = false
    vm_ipv4_address = "192.168.1.11/24"
    vm_ipv4_gateway = "192.168.1.1"
    dns_servers     = ["1.1.1.1", "8.8.8.8"]
  }
}

# versions.tf

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = ">= 0.86.0, < 0.87.0"
    }
  }
}


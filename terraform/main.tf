terraform {
  backend "pg" {}
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.2-rc04"
    }
    dns = {
      source  = "hashicorp/dns"
      version = "3.4.3"
    }
  }
}

provider "proxmox" {
  # Configuration options
  pm_api_url    = var.pm_api_url
  pm_user       = var.pm_user
  pm_password   = var.pm_password
  pm_log_enable = true
  pm_log_file   = "/tmp/terraform-plugin-proxmox.log"
  pm_debug      = true
  pm_log_levels = {
    _default    = "debug"
    _capturelog = ""
  }
}

provider "dns" {
  update {
    server        = "192.168.55.3"
    key_name      = "lab-astr0rack-key."
    key_algorithm = "hmac-sha256"
    key_secret    = var.dns_key_secret
  }
}

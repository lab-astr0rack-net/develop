variable "pm_api_url" {
  default = "https://proxmox.lab.astr0rack.net/api2/json"
}

variable "pm_user" {
  default = "terraform@pve"
}

variable "pm_password" {
  default   = "CHANGEME"
  sensitive = true
}

variable "pm_node" {
  default = "proxmox"
}

variable "dns_key_secret" {
  default   = ""
  sensitive = true
}

variable "vm_name" {
  default = "dev"
}

variable "vm_user" {
  default = ""
}

variable "vm_ssh_key" {
  default = ""
}

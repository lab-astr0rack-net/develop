resource "proxmox_vm_qemu" "dev-vm" {
  name        = var.vm_name
  description = "Ephemeral Dev VM"
  qemu_os     = "l26"
  bios        = "ovmf"
  pool        = "lab"
  # Need to specify ide0 so the VM can see cloudinit CD
  boot        = "order=virtio0;ide0"
  target_node = var.pm_node
  onboot      = true
  startup     = "order=2"
  skip_ipv6   = true

  cpu {
    sockets = 1
    cores   = 2
  }

  memory     = 4096
  agent      = 1
  clone      = "ubuntu-docker"
  full_clone = "false"
  scsihw     = "virtio-scsi-single"

  sshkeys   = var.vm_ssh_key
  ciuser    = var.vm_user
  ipconfig0 = "ip=dhcp,ip6=auto"

  disks {
    virtio {
      virtio0 {
        ignore = true
      }
    }
    ide {
      ide0 {
        cloudinit {
          storage = "local"
        }
      }
    }
  }

  network {
    id     = 0
    bridge = "vmbr20"
    model  = "virtio"
  }

  os_type = "cloud-init"

}

resource "dns_a_record_set" "www" {
  zone = "lab.astr0rack.net."
  name = var.vm_name
  addresses = [
    proxmox_vm_qemu.dev-vm.default_ipv4_address
  ]
  ttl = 60
}

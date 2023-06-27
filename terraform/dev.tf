resource "proxmox_vm_qemu" "dev-vm" {
  name    = var.vm_name
  desc    = "Ephemeral Dev VM"
  qemu_os = "l26"
  bios    = "ovmf"
  pool    = "lab"
  # Need to specify ide0 so the VM can see cloudinit CD
  boot        = "order=virtio0;ide0"
  target_node = var.pm_node
  onboot      = true
  startup     = "order=2"

  sockets    = 1
  cores      = 2
  memory     = 4096
  agent      = 1
  clone      = "ubuntu-docker"
  full_clone = "false"
  scsihw     = "virtio-scsi-single"

  sshkeys   = var.vm_ssh_key
  ciuser    = var.vm_user
  ipconfig0 = "ip=dhcp,ip6=auto"

  network {
    bridge = "vmbr0"
    model  = "e1000"
  }
  lifecycle {
    ignore_changes = [
      disk,
    ]
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

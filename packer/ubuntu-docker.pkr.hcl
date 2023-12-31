packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.2"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "pm_api_url" {
    type = string
	default = "https://proxmox.lab.astr0rack.net/api2/json"
}

variable "pm_user" {
    type = string
	default = "terraform@pve"
}

variable "pm_password" {
    type = string
    sensitive = true
}

variable "http_address" {
	type = string
}

# Resource Definiation for the VM Template
source "proxmox-iso" "ubuntu-docker" {
 
    # Proxmox Connection Settings
    proxmox_url = "${var.pm_api_url}"
    username = "${var.pm_user}"
    password = "${var.pm_password}"
    
    # VM General Settings
    node = "proxmox"
    vm_name = "ubuntu-docker"
	vm_id = "998"
    template_description = "Ubuntu Server Image with Docker pre-installed"
	bios = "ovmf"
	boot = "order=virtio0;ide2"
	pool = "template"

	efi_config {
	  efi_storage_pool = "data"
	  pre_enrolled_keys =  true
	  efi_type =  "4m"
	}

	iso_download_pve = true
    iso_url = "https://releases.ubuntu.com/jammy/ubuntu-22.04.2-live-server-amd64.iso"
	iso_checksum = "5e38b55d57d94ff029719342357325ed3bda38fa80054f9330dc789cd2d43931"
    iso_storage_pool = "local"
    unmount_iso = true

    # VM System Settings
    qemu_agent = true

    # VM Hard Disk Settings
    scsi_controller = "virtio-scsi-pci"

    disks {
        disk_size = "20G"
        format = "raw"
        storage_pool = "data"
        type = "virtio"
    }

    # VM CPU Settings
    cores = "1"
    
    # VM Memory Settings
    memory = "2048" 

    # VM Network Settings
    network_adapters {
        model = "virtio"
        bridge = "vmbr99"
        firewall = "false"
    } 

    # VM Cloud-Init Settings
    cloud_init = true
    cloud_init_storage_pool = "local"

    # PACKER Boot Commands
    boot_command = [
        "<esc><wait>",
        "e<wait>",
        "<down><down><down><end>",
        "<bs><bs><bs><bs><wait>",
        "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
        "<f10><wait>"
    ]
    boot_wait = "5s"

    # PACKER Autoinstall Settings
    http_directory = "http" 
    # (Optional) Bind IP Address and Port
    http_bind_address = "${var.http_address}"
    http_port_min = 8888
    http_port_max = 8888

    ssh_username = "ghactions"
	ssh_private_key_file = "/root/.ssh/id_ed25519"

    # Raise the timeout, when installation takes longer
    ssh_timeout = "20m"
}

# Build Definition to create the VM Template
build {

    name = "ubuntu-docker"
    sources = ["source.proxmox-iso.ubuntu-docker"]

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #1
    provisioner "shell" {
        inline = [
            "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
            "sudo rm /etc/ssh/ssh_host_*",
            "sudo truncate -s 0 /etc/machine-id",
            "sudo apt -y autoremove --purge",
            "sudo apt -y clean",
            "sudo apt -y autoclean",
            "sudo cloud-init clean",
            "sudo rm -f /etc/cloud/cloud.cfg.d/subiquity-disable-cloudinit-networking.cfg",
            "sudo sync"
        ]
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #2
    provisioner "file" {
        source = "files/99-pve.cfg"
        destination = "/tmp/99-pve.cfg"
    }

    # Provisioning the VM Template for Cloud-Init Integration in Proxmox #3
    provisioner "shell" {
        inline = [ "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg" ]
    }

    # Provisioning the VM Template with Docker Installation #4
    provisioner "shell" {
        inline = [
            "sudo apt-get -o Acquire::ForceIPv4=true install -y ca-certificates curl gnupg lsb-release",
            "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg",
            "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable\" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null",
            "sudo apt-get -o Acquire::ForceIPv4=true -y update",
            "sudo apt-get -o Acquire::ForceIPv4=true install -y docker-ce docker-ce-cli containerd.io"
        ]
    }
}

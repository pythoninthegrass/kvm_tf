provider "libvirt" {
  # localhost
  # uri = "qemu:///system"

  # ssh
  uri = "qemu+ssh://${local.server_user}@${local.server_host}/system?no_verify=1"
}

resource "random_id" "rng" {
  byte_length = 8
}

resource "random_id" "vm_id" {
  byte_length = 8
}

# Generate MAC addresses for each VM
resource "random_id" "vm_mac" {
  count       = var.vm_count
  byte_length = 6
}

# Create custom network with static routes
resource "libvirt_network" "vm_network" {
  name      = "vm-network-${random_id.rng.hex}"
  mode      = "nat"
  domain    = "vm.local"
  addresses = ["192.168.100.0/24"]
  autostart = true

  dhcp {
    enabled = false  # Disable DHCP for static IP assignment
  }

  # Static routes - example routes to external networks
  routes {
    cidr    = "10.0.0.0/8"
    gateway = "192.168.100.1"
  }
  
  routes {
    cidr    = "172.16.0.0/12"
    gateway = "192.168.100.1"
  }
  
  routes {
    cidr    = "203.0.113.0/24"
    gateway = "192.168.100.1"
  }

  dns {
    enabled    = true
    local_only = false
  }
  
  lifecycle {
    ignore_changes = [
      dhcp[0].enabled, # see https://github.com/dmacvicar/terraform-provider-libvirt/issues/998
    ]
  }
}

resource "libvirt_pool" "ubuntu" {
  name = "ubuntu"
  type = "dir"
  target {
    path = "${var.libvirt_disk_path}-${random_id.rng.hex}"
  }
}

resource "libvirt_volume" "ubuntu-qcow2-base" {
  name   = "ubuntu-qcow2-base"
  pool   = libvirt_pool.ubuntu.name
  source = var.ubuntu_24_img_url
  format = "qcow2"
}

resource "libvirt_volume" "ubuntu-qcow2" {
  count           = var.vm_count
  name            = "ubuntu-qcow2-${count.index}"
  pool            = libvirt_pool.ubuntu.name
  base_volume_id  = libvirt_volume.ubuntu-qcow2-base.id
  format          = "qcow2"
}

resource "libvirt_cloudinit_disk" "commoninit" {
  count          = var.vm_count
  name           = "commoninit-${count.index}.iso"
  user_data      = local.user_data
  network_config = templatefile("${path.module}/config/network_config.yml", {
    vm_ip = "192.168.100.${10 + count.index}"
  })
  pool           = libvirt_pool.ubuntu.name
}


resource "libvirt_domain" "domain-ubuntu" {
  count  = var.vm_count
  name   = "${var.vm_hostname_prefix}${count.index + 1}-${random_id.vm_id.hex}"
  memory = 2048
  vcpu   = 2

  cloudinit = libvirt_cloudinit_disk.commoninit[count.index].id

  network_interface {
    network_id     = libvirt_network.vm_network.id
    mac            = "52:54:00:${substr(random_id.vm_mac[count.index].hex, 0, 2)}:${substr(random_id.vm_mac[count.index].hex, 2, 2)}:${substr(random_id.vm_mac[count.index].hex, 4, 2)}"
    addresses      = ["192.168.100.${10 + count.index}"]
    hostname       = "${var.vm_hostname_prefix}${count.index + 1}-${random_id.vm_id.hex}"
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
    type        = "pty"
    target_type = "virtio"
    target_port = "1"
  }

  disk {
    volume_id = libvirt_volume.ubuntu-qcow2[count.index].id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }


  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "echo 'Cloud-init completed, system ready'"
    ]

    connection {
      type         = "ssh"
      user         = var.ssh_username
      host         = "192.168.100.${10 + count.index}"
      private_key  = file(var.ssh_private_key)
      timeout      = "2m"
      agent        = false
      host_key     = null

      bastion_host        = local.server_host
      bastion_user        = local.server_user
      bastion_private_key = file(var.ssh_private_key)
    }
  }

  # provisioner "local-exec" {
  #   command = <<EOT
  #       ansible-playbook ${path.module}/tasks/playbook.yml \
  #           -i '192.168.100.${10 + count.index},' \
  #           -u ${var.ssh_username} \
  #           --private-key ${var.ssh_private_key}
  #     EOT

  #   environment = {
  #     ANSIBLE_HOST_KEY_CHECKING = "False"
  #   }
  # }
}

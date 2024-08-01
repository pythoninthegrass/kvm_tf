provider "libvirt" {
  # localhost
  # uri = "qemu:///system"

  # ssh
  uri = "qemu+ssh://${local.server_user}@${local.server_host}/system"
}

resource "random_id" "rng" {
  keepers = {
    first = timestamp()
  }
  byte_length = 8
}

resource "libvirt_pool" "ubuntu" {
  name = "ubuntu"
  type = "dir"
  path = "${var.libvirt_disk_path}-${random_id.rng.hex}"
}

resource "libvirt_volume" "ubuntu-qcow2" {
  name   = "ubuntu-qcow2"
  pool   = libvirt_pool.ubuntu.name
  source = var.ubuntu_24_img_url
  format = "qcow2"
}

resource "libvirt_cloudinit_disk" "commoninit" {
  name           = "commoninit.iso"
  user_data      = local.user_data
  network_config = local.network_config
  pool           = libvirt_pool.ubuntu.name
}

resource "libvirt_domain" "domain-ubuntu" {
  count  = var.vm_count
  name   = "${var.vm_hostname_prefix}${count.index + 1}"
  memory = 2048
  vcpu   = 2

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_name   = "default"
    wait_for_lease = true
    hostname       = "${var.vm_hostname_prefix}${count.index + 1}"
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
    volume_id = libvirt_volume.ubuntu-qcow2.id
  }

  graphics {
    type        = "spice"
    listen_type = "address"
    autoport    = true
  }

  provisioner "remote-exec" {
    inline = [
      "echo 'Hello World'"
    ]

    connection {
      type        = "ssh"
      user        = var.ssh_username
      host        = self.network_interface[0].addresses[0]
      private_key = file(local.ssh_private_key)
      timeout     = "2m"
    }
  }

  provisioner "local-exec" {
    command = <<EOT
        ansible-playbook ${path.module}/ansible/playbook.yml \
            --extra-vars 'target_host=["${self.network_interface[0].addresses[0]}"]' \
            -u ${var.ssh_username} \
            --private-key ${local.ssh_private_key}
      EOT
  }
}

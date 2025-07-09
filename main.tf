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
  name           = "commoninit.iso"
  user_data      = local.user_data
  network_config = local.network_config
  pool           = libvirt_pool.ubuntu.name
}

resource "null_resource" "wait_for_vm" {
  count = var.vm_count

  provisioner "local-exec" {
    command = "sleep 60"
  }
}

resource "libvirt_domain" "domain-ubuntu" {
  count  = var.vm_count
  name   = "${var.vm_hostname_prefix}${count.index + 1}-${random_id.vm_id.hex}"
  memory = 2048
  vcpu   = 2

  cloudinit = libvirt_cloudinit_disk.commoninit.id

  network_interface {
    network_name   = "default"
    wait_for_lease = true
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

  depends_on = [null_resource.wait_for_vm]

  provisioner "remote-exec" {
    inline = [
      "cloud-init status --wait",
      "echo 'Cloud-init completed, system ready'"
    ]

    connection {
      type         = "ssh"
      user         = var.ssh_username
      host         = self.network_interface[0].addresses[0]
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
  #           -i '${self.network_interface[0].addresses[0]},' \
  #           -u ${var.ssh_username} \
  #           --private-key ${var.ssh_private_key}
  #     EOT

  #   environment = {
  #     ANSIBLE_HOST_KEY_CHECKING = "False"
  #   }
  # }
}

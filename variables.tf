# dot_env: https://stackoverflow.com/a/76194380/15454191
locals {
  dot_env_file_path = "./.env"
  dot_env_regex     = "(?m:^\\s*([^#\\s]\\S*)\\s*=\\s*[\"']?(.*[^\"'\\s])[\"']?\\s*$)"
  dot_env           = { for tuple in regexall(local.dot_env_regex, file(local.dot_env_file_path)) : tuple[0] => sensitive(tuple[1]) }
  server_user       = local.dot_env["SERVER_USER"]
  server_host       = local.dot_env["SERVER_HOST"]
  user_data         = templatefile("${path.module}/config/cloud_init.yml", {})
  network_config    = templatefile("${path.module}/config/network_config.yml", {})
}

variable "libvirt_disk_path" {
  description = "path for libvirt pool"
  type        = string
  default     = "/var/lib/libvirt/images"
}

variable "ubuntu_24_img_url" {
  description = "ubuntu 24.04 image"
  type        = string
  default     = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

variable "vm_hostname_prefix" {
  description = "vm hostname prefix"
  type        = string
  default     = "ubuntu-tf-"
}

variable "vm_count" {
  description = "number of VMs to create"
  type        = number
  default     = 3
}

variable "ssh_username" {
  description = "the ssh user to use"
  type        = string
  default     = "ubuntu"
}

variable "ssh_private_key" {
  description = "path to ssh private key"
  type        = string
  default     = "~/.ssh/id_rsa"
}

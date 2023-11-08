# dot_env: https://stackoverflow.com/a/76194380/15454191
locals {
  dot_env_file_path = "./.env"
  dot_env_regex     = "(?m:^\\s*([^#\\s]\\S*)\\s*=\\s*[\"']?(.*[^\"'\\s])[\"']?\\s*$)"
  dot_env           = { for tuple in regexall(local.dot_env_regex, file(local.dot_env_file_path)) : tuple[0] => sensitive(tuple[1]) }
  server_user       = local.dot_env["SERVER_USER"]
  server_host       = local.dot_env["SERVER_HOST"]
}

variable "libvirt_disk_path" {
  description = "path for libvirt pool"
  default     = "/opt/kvm/pool"
}

variable "ubuntu_24_img_url" {
  description = "ubuntu 24.04 image"
  default     = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}

variable "vm_hostname" {
  description = "vm hostname"
  default     = "ubuntu-tf"
}

variable "ssh_username" {
  description = "the ssh user to use"
  default     = "ubuntu"
}

variable "ssh_private_key" {
  description = "the private key to use"
  default     = "~/.ssh/id_rsa"
}

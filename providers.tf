terraform {
  required_version = ">= 1.9.3"

  backend "local" {}

  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "0.8.3"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.2"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.5.1"
    }
  }
}

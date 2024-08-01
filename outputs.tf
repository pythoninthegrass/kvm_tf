output "vm_names" {
  value = libvirt_domain.domain-ubuntu[*].name
}

output "ips" {
  value = libvirt_domain.domain-ubuntu[*].network_interface[0].addresses[0]
}

output "urls" {
  value = [for vm in libvirt_domain.domain-ubuntu : "http://${vm.network_interface[0].addresses[0]}"]
}

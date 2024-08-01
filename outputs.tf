output "ips" {
  value = libvirt_domain.domain-ubuntu[*].network_interface[0].addresses[0]
}

output "urls" {
  value = [for ip in libvirt_domain.domain-ubuntu[*].network_interface[0].addresses[0] : "http://${ip}"]
}

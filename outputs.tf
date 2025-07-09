output "vm_names" {
  value = libvirt_domain.domain-ubuntu[*].name
}

output "ips" {
  value = [for i in range(var.vm_count) : "192.168.100.${10 + i}"]
  description = "Static IP addresses of the VMs"
}

output "urls" {
  value = [for i in range(var.vm_count) : "http://192.168.100.${10 + i}"]
  description = "URLs to access the VMs"
}


output "mac_addresses" {
  value = [for i in range(var.vm_count) : "52:54:00:${substr(random_id.vm_mac[i].hex, 0, 2)}:${substr(random_id.vm_mac[i].hex, 2, 2)}:${substr(random_id.vm_mac[i].hex, 4, 2)}"]
}

output "network_info" {
  value = {
    network_name = libvirt_network.vm_network.name
    network_cidr = "192.168.100.0/24"
    gateway      = "192.168.100.1"
    dns_domain   = "vm.local"
    static_routes = [
      "10.0.0.0/8 via 192.168.100.1",
      "172.16.0.0/12 via 192.168.100.1",
      "203.0.113.0/24 via 192.168.100.1"
    ]
  }
}

# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Terraform/Cloud-Init/Ansible boilerplate for the libvirt (KVM) Terraform provider. It creates Ubuntu VMs on KVM/libvirt hypervisors with cloud-init configuration and optional Ansible provisioning.

## Architecture

- **Terraform**: Infrastructure as code for VM provisioning using the libvirt provider
- **Cloud-Init**: VM initialization and configuration (config/cloud_init.yml, config/network_config.yml)
- **Ansible**: Optional configuration management (tasks/playbook.yml)
- **Go Tests**: Infrastructure testing using Terratest

The main Terraform configuration creates:
- libvirt_pool for storage
- libvirt_volume for VM disk images
- libvirt_cloudinit_disk for cloud-init configuration (one per VM for static IP assignment)
- libvirt_network for custom network with static routes
- libvirt_domain for VM instances

## Common Commands

### Task Runner (Primary)
```bash
# List all available tasks
task

# Terraform operations
task tf:init
task tf:plan
task tf:apply
task tf:destroy

# Testing
task test          # Run Go tests with Terratest
task init          # Initialize Go test modules

# Linting
task lint          # Run tflint
```

### Direct Terraform

```bash
terraform init
terraform validate
terraform fmt
terraform plan -out tfplan
terraform apply tfplan
terraform destroy
```

### Development Environment

```bash
# Setup development environment
devbox shell       # Enter devbox environment with all dependencies

# Python virtual environment (auto-created in devbox)
uv venv .venv
source .venv/bin/activate
```

### Testing

```bash
# Run infrastructure tests
cd tests/
go test -v -timeout 5m
```

### Debugging

```bash
# Check libvirt status
sudo systemctl status libvirtd

# List libvirt networks
virsh net-list --all

# Create and start the default libvirt network if needed
# If network already exists but not visible, try:
sudo virsh net-start default
sudo virsh net-autostart default

# If network doesn't exist, create it:
# sudo virsh net-define /usr/share/libvirt/networks/default.xml

# Check bridge interface status
ip a show virbr0

# Clean up orphaned VMs after failed vagrant destroy
for vm in $(virsh list --all | awk '/ubuntu-tf/ {print $2}'); do virsh destroy "$vm" 2>/dev/null; virsh undefine "$vm" 2>/dev/null; done

# Fix terraform destroy issues with libvirt storage pools
# If terraform destroy fails with "Directory not empty" error:
# 1. Check pool directory contents
ssh dev-ts "sudo ls -la /var/lib/libvirt/images-<pool-id>/"

# 2. Remove leftover files/directories
ssh dev-ts "sudo rm -rf /var/lib/libvirt/images-<pool-id>/"

# 3. Manually destroy and undefine the pool
ssh dev-ts "sudo virsh pool-destroy <pool-name> || true; sudo virsh pool-undefine <pool-name> || true"

# 4. Remove pool from terraform state
terraform state rm libvirt_pool.<pool-name>

# 5. Retry terraform destroy
terraform destroy -auto-approve
```

## Key Configuration Files

- `main.tf`: Primary Terraform configuration
- `variables.tf`: Input variables
- `outputs.tf`: Output values
- `config/cloud_init.yml`: Cloud-init user data
- `config/network_config.yml`: Network configuration (templated per VM for static IPs)
- `tasks/playbook.yml`: Ansible playbook
- `pyproject.toml`: Python/Ansible dependencies
- `devbox.json`: Development environment configuration

## Network Configuration

### Static IP Assignment
- VMs are assigned static IP addresses: `192.168.100.10`, `192.168.100.11`, `192.168.100.12`
- Custom libvirt network: `192.168.100.0/24` with DHCP disabled
- Each VM gets individual cloud-init disk with specific IP configuration
- Static IPs are configured both in Terraform network interface and cloud-init

### Static Routes
The configuration includes static routes to external networks:
- `10.0.0.0/8` via `192.168.100.1`
- `172.16.0.0/12` via `192.168.100.1`
- `203.0.113.0/24` via `192.168.100.1`

Routes are configured at two levels:
1. **Network level**: libvirt network resource with `routes` blocks
2. **VM level**: cloud-init network configuration with `routes` section

### SSH Access
VMs are accessible via jumpbox/bastion host:
```bash
# Example SSH config entry
Host ubuntu-tf-1
    HostName 192.168.100.10
    User ubuntu
    IdentityFile ~/.ssh/id_rsa
    ProxyJump ubuntu@100.72.47.104
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null
```

## Linting

```bash
# Lint markdown files
markdownlint -c .markdownlint.jsonc README.md
```

## Memories

- Remote host is ubuntu 24.04. To use virsh or debug file system issues, use `ssh dev-ts <command>`
- Static IP configuration requires DHCP disabled on libvirt network and individual cloud-init disks per VM
- DHCP host reservations are not supported in terraform-provider-libvirt - use static IP assignment instead
- When DHCP is disabled, remove `wait_for_lease = true` and use static IPs in provisioner connections

## Documentation References

<!-- * NOTE: keep doc references at bottom of file (EOF) -->

- libvirt terraform provider: <https://registry.terraform.io/providers/dmacvicar/libvirt/latest/docs>
- working libvirt tf examples: <https://github.com/rgl/terraform-libvirt-ubuntu-example>
- virsh (libvirt management): <https://www.libvirt.org/manpages/virsh.html>
- network xml format: <https://libvirt.org/formatnetwork.html>
- cloud-init: <https://cloudinit.readthedocs.io/en/latest/reference/index.html>

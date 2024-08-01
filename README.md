# KVM Terraform Example

Terraform/Cloud-Init/Ansible boilerplate for libvirt (KVM) Terraform provider

## Minimum Requirements

* [libvirt](https://libvirt.org/downloads.html)
  * [Installing libvirt and virt-install on Fedora Linux — Fedora Developer Portal](https://developer.fedoraproject.org/tools/virtualization/installing-libvirt-and-virt-install-on-fedora-linux.html)
* [Terraform](https://www.terraform.io/downloads.html)
* [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)


## Recommended Requirements

* [devbox](https://www.jetify.com/devbox/docs/installing_devbox/)
* [orbstack](https://docs.orbstack.dev/install)
  * Replaces Docker Desktop on macOS

## Quickstart

```bash
# deploy
terraform init
terraform plan -out tfplan
terraform apply tfplan

# outputs
terraform show -json | jq -r '.values.outputs.ip.value'

# test nginx
vm_ip=$(terraform output -json ip | jq -r '.')
curl -I "$vm_ip"

# destroy
terraform destroy
```

## Development

### Testing
```bash
cd test/
go mod init github.com/pythoninthegrass/kvm_tf
go mod tidy
go get github.com/gruntwork-io/terratest/modules/terraform
go test -v -timeout 5m
```

## TODO

* [Issues](https://github.com/pythoninthegrass/kvm_tf/issues)
* Tweak cloud-init

## Further Reading

* [Virtualization – Getting Started :: Fedora Docs](https://docs.fedoraproject.org/en-US/quick-docs/virtualization-getting-started/)
* [Using the Libvirt Provisioner With Terraform for KVM - Ruan Bekker's Blog](https://blog.ruanbekker.com/blog/2020/10/08/using-the-libvirt-provisioner-with-terraform-for-kvm/)
* [KVM in Terraform // Dan's Tech Journey](https://danstechjourney.com/posts/kvm-terraform/)
* [KVM: Terraform and cloud-init to create local KVM resources | Fabian Lee : Software Engineer](https://fabianlee.org/2020/02/22/kvm-terraform-and-cloud-init-to-create-local-kvm-resources/)
* [Ubuntu Cloud Images](https://cloud-images.ubuntu.com/)

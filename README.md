# KVM Terraform Example

Terraform/Cloud-Init/Ansible boilerplate for libvirt (KVM) Terraform provider

## Setup
### Minimum Requirements
* [libvirt](https://libvirt.org/downloads.html)
  * [Installing libvirt and virt-install on Fedora Linux — Fedora Developer Portal](https://developer.fedoraproject.org/tools/virtualization/installing-libvirt-and-virt-install-on-fedora-linux.html)
* [Terraform](https://www.terraform.io/downloads.html)
* [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html)
  * See [Recommended Requirements](#recommended-requirements) for Python setup via `asdf`
    ```bash
    # setup python venv
    python3 -m venv .venv

    # activate venv
    source .venv/bin/activate

    # install ansible
    python3 -m pip install ansible
    ```

### Recommended Requirements
* [asdf](https://asdf-vm.com/#/core-manage-asdf-vm)
  * Covers Terraform, Python, and Go via
    ```bash
    asdf install
    ```

## Quickstart
```bash
# install libvirt provider
./bootstrap

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

## TODO
* [Issues](https://github.com/pythoninthegrass/kvm_tf/issues)
* Tweak cloud-init
* Run terraform against remote linux box
* QA test

## Further Reading
[Virtualization – Getting Started :: Fedora Docs](https://docs.fedoraproject.org/en-US/quick-docs/virtualization-getting-started/)

[Using the Libvirt Provisioner With Terraform for KVM - Ruan Bekker's Blog](https://blog.ruanbekker.com/blog/2020/10/08/using-the-libvirt-provisioner-with-terraform-for-kvm/)

[KVM in Terraform // Dan's Tech Journey](https://danstechjourney.com/posts/kvm-terraform/)

[KVM: Terraform and cloud-init to create local KVM resources | Fabian Lee : Software Engineer](https://fabianlee.org/2020/02/22/kvm-terraform-and-cloud-init-to-create-local-kvm-resources/)

[Ubuntu Cloud Images](https://cloud-images.ubuntu.com/)

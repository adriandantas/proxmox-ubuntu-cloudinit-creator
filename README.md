# ProxMox VE Cloud-Init Template Creation script

This is a handy script to speed up the creation of [Ubuntu Cloud](https://ubuntu.cloud/) templates that can be configured through Cloud-Init
in [ProxMox VE](http://www.proxmox.com/) server virtualization management solution .

## Requirements
The script needs be executed directly on a [ProxMox](http://www.prox.com/) host. It also requires the installation of
[libguestfs-tools](https://libguestfs.org/) package. The presence of the package will be verified.

## Usage
The script should be executed in the ProxMox host running as root.
Running it without arguments will create an [Ubuntu Cloud 24.04](https://cloud-images.ubuntu.com/releases/noble/release/)
template.

```shell
pm-tpl-create.sh
```
## Script arguments
| Argument | Description              | Default value                                  |
|:---------|:-------------------------|:-----------------------------------------------|
| -h       | Help                     | N/A                                            |
| -v       | vmid                     | 9000                                           |
| -t       | Template name            | ubuntu-2404-cloudinit-template                 |
| -m       | Memory                   | 1024 Kb                                        |
| -c       | Cores                    | 1                                              |
| -r       | Cloud images repository. | https://cloud-images.ubuntu.com/noble/current/ |
| -i       | Image name.              | noble-server-cloudimg-amd64.img                |              

## Examples

### Creating an [Ubuntu Cloud 24.04 (Noble Numbat)](https://cloud-images.ubuntu.com/noble/)
```shell
pm-tpl-create.sh -t "ubuntu-24-04-tpl" \
   -r https://cloud-images.ubuntu.com/noble/current/ \
   -i noble-server-cloudimg-amd64.img   
```


## Overview of commands executed by the script
Default values used by the script
```shell
UBUNTU_REPO="https://cloud-images.ubuntu.com/noble/current/"
UBUNTU_IMG="focal-noble-cloudimg-amd64.img"
VMID=9000
TEMPLATE_NAME="ubuntu-2404-cloudinit-template"
MEMORY=1024
CORES=1
```
The value can be redefined using optional arguments.

Downloads selected Ubuntu cloud image.
```shell
wget "$UBUNTU_REPO/$UBUNTU_IMG"
```
Installs QEMU guest agent into the image.
```shell
virt-customize -a $UBUNTU_IMG --install qemu-guest-agent
```
Configures images with parameters.
```shell
qm create $VMID --name $TEMPLATE_NAME --memory $MEMORY --cores $CORES --net0 virtio,bridge=vmbr0
qm importdisk $VMID $UBUNTU_IMG local-lvm
qm set $VMID --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-$VMID-disk-0
qm set $VMID --ide2 local-lvm:cloudinit
qm set $VMID --boot c --bootdisk scsi0
qm set $VMID --serial0 socket --vga serial0
qm set $VMID --agent enabled=1
qm template $VMID
```
## Author
Adrian Dantas
[@adriandantas](https://github.com/adriandantas)

## Acknowledgments
Create Proxmox cloud-init template - https://www.yanboyang.com/clouldinit/
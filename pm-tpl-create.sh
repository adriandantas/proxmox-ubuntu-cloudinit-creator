#!/usr/bin/env bash
WORKDIR="./work"
UBUNTU_REPO="https://cloud-images.ubuntu.com/focal/current/"
UBUNTU_IMG="focal-server-cloudimg-amd64.img"
VMID=9000
TEMPLATE_NAME="ubuntu-2004-cloudinit-template"
MEMORY=1024
CORES=1

Help()
{
   # Display Help
   echo "Usage: proxmox-setup [OPTION...]"
   echo
   echo "-v     vmid."
   echo "           default: $VMID"
   echo "-t     Template name."
   echo "           default: $TEMPLATE_NAME"
   echo "-m     Memory in Kb."
   echo "           default: $MEMORY"
   echo "-c     Cores."
   echo "           default: $CORES"
   echo "-r     Cloud images repository."
   echo "           default: $UBUNTU_REPO"
   echo "-i     Image name."
   echo "           default: $UBUNTU_IMG"
   echo "-h     Help."
   echo
}

while getopts "v:t:m:c:r:i:h" option
do
    case "${option}" in
        v) VMID=${OPTARG};;
        t) TEMPLATE_NAME=${OPTARG};;
        m) MEMORY=${OPTARG};;
        c) CORES=${OPTARG};;
        r) UBUNTU_REPO=${OPTARG};;
        i) UBUNTU_IMG=${OPTARG};;
        h) Help
           exit;;
    esac
done

echo "Creating template with the following parameters:"
echo "  template name: $TEMPLATE_NAME"
echo "  wmid: $VMID"
echo "  memory: $MEMORY"
echo "  cores: $CORES"

echo "Starting  Ubuntu cloud image setup"

dpkg -l libguestfs-tools > /dev/null 2>&1

if [ $? == 1 ]; then
  echo "Missing package libguestfs-tools."
  echo "Install package with command:"
  echo "apt-get install libguestfs-tools"
  exit 1
fi

if [ -d "$WORKDIR" ]; then
  echo "Work directory $WORKDIR already exists"
else
  mkdir $WORKDIR
  echo "Work directory $WORKDIR created"
fi

cd $WORKDIR

if [ -f "MD5SUMS" ]; then
  echo "FILE MD5SUMS already exists"
else
  echo "Downloading MD5SUMS"
  wget "$UBUNTU_REPO/MD5SUMS" > /dev/null 2>&1
  if [ $? == 1 ]; then
    echo "Error: Filed to download $UBUNTU_REPO/MD5SUMS" >&2
    exit 1
  fi
fi

if [ -f "$UBUNTU_IMG" ]; then
  echo "Image $UBUNTU_IMG already exists"
else
  echo "Downloading $UBUNTU_REPO/$UBUNTU_IMG"
  wget "$UBUNTU_REPO/$UBUNTU_IMG"
  if [ $? != 0 ]; then
    echo "Error: Filed to download $UBUNTU_REPO/$UBUNTU_IMG" >&2
    exit 1
  fi
fi

grep $UBUNTU_IMG MD5SUMS | md5sum -c > /dev/null 2>&1
if [ $? == 0 ]; then
  echo "$UBUNTU_IMG md5sum check passed"

else
  echo "Error: $UBUNTU_IMG md5sum check failed" >&2
    exit 1
fi

echo "Installing QEMU agent into VM image"
virt-customize -a $UBUNTU_IMG --install qemu-guest-agent

qm create $VMID --name $TEMPLATE_NAME --memory $MEMORY --cores $CORES --net0 virtio,bridge=vmbr0
qm importdisk $VMID $UBUNTU_IMG local-lvm
qm set $VMID --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-$VMID-disk-0
qm set $VMID --ide2 local-lvm:cloudinit
qm set $VMID --boot c --bootdisk scsi0
qm set $VMID --serial0 socket --vga serial0
qm set $VMID --agent enabled=1
qm template $VMID
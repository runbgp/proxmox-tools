#!/bin/bash
#Download Ubuntu cloud image and SSH key
wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
wget https://github.com/runbgp.keys

#Create an Ubuntu Server 22.04 LTS template (VMID 4001)
qm create 4001 --memory 1024 --net0 virtio,bridge=vmbr$vlan
qm importdisk 4001 jammy-server-cloudimg-amd64.img local-lvm
qm set 4001 --scsihw virtio-scsi-pci --virtio0 local-lvm:vm-4001-disk-0
qm set 4001 --ide2 local-lvm:cloudinit
qm set 4001 --boot c --bootdisk virtio0
qm set 4001 --vga std
qm template 4001
sleep 30

#Define VM variables
vmid=$(pvesh get /cluster/nextid)
hostname=ia
cores=1
memory=1024
username=ubuntu
password=draPH4
domain=ix0.io
disksize=20G
vlan=10
ip=10.0.10.50
gw=10.0.10.1
dns=10.0.10.10
sshkey=runbgp.keys

#Clone template and create a VM
qm clone 4001 $vmid --name $hostname
qm set $vmid --cpu host
qm set $vmid --cores $cores
qm set $vmid --memory $memory
qm set $vmid --ciuser $username
qm set $vmid --cipassword $password
qm set $vmid --searchdomain $domain
qm set $vmid --ipconfig0 ip=$ip,gw=$gw
qm set $vmid --nameserver $dns
qm set $vmid --sshkey $sshkey
qm resize $vmid virtio0 $disksize
qm start $vmid
sleep 5

#Cleanup
rm jammy-server-cloudimg-amd64.img
rm $sshkey
qm destroy 4001
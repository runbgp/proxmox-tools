#!/bin/bash
echo "Welcome to runbgp's Proxmox Tools VM creation script!"
sleep 2
echo "#######################################################################"
echo "# Please specify the operating system of the VM you'd like to create. #"
echo "# 1. Ubuntu 22.04 LTS | 2. Ubuntu 20.04 LTS | 3. Ubuntu 18.04 LTS     #"
echo "#######################################################################"
read -p 'OS: ' os

#Download Ubuntu cloud image
if [ $os -eq 1 ]; then
    image=jammy-server-cloudimg-amd64.img
    echo "###################################"
    echo "# Downloading Ubuntu 22.04 LTS... #"
    echo "###################################"
    wget https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img
elif [ $os -eq 2 ]; then
    image=focal-server-cloudimg-amd64.img
    echo "###################################"
    echo "# Downloading Ubuntu 20.04 LTS... #"
    echo "###################################"
    wget https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img
elif [ $os -eq 3 ]; then
    image=bionic-server-cloudimg-amd64.img
    echo "###################################"
    echo "# Downloading Ubuntu 18.04 LTS... #"
    echo "###################################"
    wget https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img
fi
echo $image has been downloaded.
sleep 5

#Download SSH key
echo "###################################################"
echo "# Would you like to add an SSH key to cloud-init? #"
echo "###################################################"
read -p '(y)es/(n)o: ' sshchoice

if sshchoice=y; then
echo "#########################################################################"
echo "# Please enter the GitHub username to download your public key(s) from. #"
echo "#########################################################################"
read -p 'GitHub Username: ' githubusername
wget https://github.com/$githubusername.keys
echo "##################################################################################"
echo "# The following SSH keys have been downloaded and will be applied to cloud-init. #"
echo "##################################################################################"
cat $githubusername.keys
sleep 5
elif sshchoice=n; then
echo "################################################"
echo "#You chose to not add an SSH key. Proceeding...#"
echo "################################################"
fi

#Define VM configuration variables
echo "####################"
echo "# VM Configuration #"
echo "####################"
sleep 2
read -p 'Hostname: ' hostname
read -p 'CPU Cores: ' cores
read -p 'RAM (MB): ' memory
read -p 'Datastore (e.g. local-lvm): ' datastore
read -p 'Disk (e.g. 20G): ' disk
read -p 'cloud-init Username: ' username
read -sp 'Password: ' password
echo
read -p 'DNS Domain: ' domain
read -p 'Network Bridge (e.g. vmbr0): ' bridge
read -p 'IPv4 Address/CIDR (e.g. 10.0.0.20/24): ' ipaddress
read -p 'IPv4 Gateway Address (e.g. 10.0.0.1): ' gwaddress
read -p 'DNS Server Address: ' dns
sleep 2

#Create VM template (VMID 4001)
echo "#########################################"
echo "# Creating a VM template (VMID 4001)... #"
echo "#########################################"
qm create 4001 --memory 1024 --net0 virtio,bridge=$bridge
qm importdisk 4001 $image $datastore
qm set 4001 --scsihw virtio-scsi-pci --virtio0 $datastore:vm-4001-disk-0
qm set 4001 --ide2 $datastore:cloudinit
qm set 4001 --boot c --bootdisk virtio0
qm set 4001 --vga std
qm template 4001
sleep 30

#Clone template and create a VM
echo "##################"
echo "# Creating VM... #"
echo "##################"
sleep 2
vmid=$(pvesh get /cluster/nextid)
qm clone 4001 $vmid --name $hostname --full
qm set $vmid --cpu host
qm set $vmid --cores $cores
qm set $vmid --memory $memory
qm set $vmid --ciuser $username
qm set $vmid --cipassword $password
qm set $vmid --searchdomain $domain
qm set $vmid --ipconfig0 ip=$ipaddress,gw=$gwaddress
qm set $vmid --nameserver $dns
qm set $vmid --sshkey $githubusername.keys
qm resize $vmid virtio0 $disk
sleep 5

#Cleanup
echo "##################"
echo "# Cleaning up... #"
echo "##################"
sleep 2
rm $image
rm $githubusername.keys
qm destroy 4001
sleep 2

echo "#########"
echo "# Done! #"
echo "#########"

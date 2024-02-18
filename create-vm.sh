#!/bin/bash

# Function to print a message inside a box
print_in_box() {
    local input="$1"
    local longest=0
    while IFS= read -r line; do
        (( ${#line} > longest )) && longest=${#line}
    done <<< "$input"

    printf '┌'
    for ((i=0; i<$longest; i++)); do printf '─'; done
    printf '┐\n'

    while IFS= read -r line; do
        printf "│%-*s│\n" "$longest" "$line"
    done <<< "$input"

    printf '└'
    for ((i=0; i<$longest; i++)); do printf '─'; done
    printf '┘\n'
}

clear
print_in_box "Welcome to runbgp's Proxmox Tools VM creation script!"
sleep 2

# Select OS
clear
print_in_box "Select the operating system of the VM you'd like to create.
1. Ubuntu 22.04 LTS 
2. Ubuntu 20.04 LTS 
3. Ubuntu 18.04 LTS"

while true; do
    read -p 'OS: ' os
    case $os in
        [1-3]) break;;
        *) print_in_box "Invalid selection. Please enter 1, 2, or 3.";;
    esac
done

# Define arrays for image names and URLs
images=("jammy-server-cloudimg-amd64.img" "focal-server-cloudimg-amd64.img" "bionic-server-cloudimg-amd64.img")
urls=("https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img" "https://cloud-images.ubuntu.com/focal/current/focal-server-cloudimg-amd64.img" "https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img")
versions=("22.04" "20.04" "18.04")

# Subtract 1 because array indices start at 0
index=$((os - 1))

# Assign the selected image and download URL
image=${images[$index]}
url=${urls[$index]}
version=${versions[$index]}

# Check if the selected image already exists
if [ -f "$image" ]; then
    clear
    print_in_box "$image already exists. Skipping download."
else
    # Download the selected image
    clear
    print_in_box "Downloading Ubuntu Server $version LTS..."
    wget $url

    clear
    print_in_box "$image has been downloaded."
fi
sleep 5

# Download SSH key
clear
print_in_box "Would you like to add an SSH key to cloud-init?"
read -p '(y)/(n): ' sshchoice

set_sshkey=false
if [ "$sshchoice" = "y" ]; then
    set_sshkey=true
    print_in_box "Would you like to download SSH keys from GitHub or paste a key?"
    read -p '(g)ithub/(p)aste: ' keychoice
    if [ "$keychoice" = "g" ]; then
        print_in_box "Enter the GitHub username to download your public key(s) from."
        read -p 'GitHub Username: ' githubusername
        wget https://github.com/$githubusername.keys
        keyfile="$githubusername.keys"
    elif [ "$keychoice" = "p" ]; then
        print_in_box "Paste your SSH public key(s) to be applied to cloud-init."
        read -p 'SSH Key: ' sshkey
        echo "$sshkey" > pasted.keys
        keyfile="pasted.keys"
    fi

    clear
    print_in_box "The following SSH keys have been downloaded and will be applied to cloud-init."
    cat $keyfile
    sleep 5
elif [ "$sshchoice" = "n" ]; then
    clear
    print_in_box "You chose to not add an SSH key! Proceeding..."
    sleep 2
fi

# Define VM configuration variables
clear
print_in_box "VM Configuration"
sleep 2
read -p 'Hostname: ' hostname
read -p 'CPU Cores: ' cores
read -p 'RAM (MB): ' memory
read -p 'Datastore (e.g. local-lvm): ' datastore
read -p 'Disk (e.g. 20G): ' disk
read -p 'cloud-init Username: ' username
read -sp 'Password: ' password
echo
read -p 'Network Bridge (e.g. vmbr0): ' bridge
read -p 'IPv4 Address/CIDR (e.g. 192.168.1.50/24): ' ipaddress
read -p 'IPv4 Gateway Address (e.g. 192.168.1.1): ' gwaddress
read -p 'Would you like to add an IPv6 address and gateway? (y/n): ' ipv6choice
if [ "$ipv6choice" = "y" ]; then
    read -p 'IPv6 Address/CIDR (e.g. 2001:db8::1/64): ' ipv6address
    read -p 'IPv6 Gateway Address (e.g. 2001:db8::1): ' ipv6gwaddress
fi
read -p 'DNS Server Address: (e.g. 1.1.1.1) ' dns
read -p 'DNS Domain: ' domain

# Create VM template (VMID 4001)
clear
print_in_box "Creating a VM template (VMID 4001)..."
qm create 4001 --memory 1024 --net0 virtio,bridge=$bridge
qm importdisk 4001 $image $datastore
qm set 4001 --scsihw virtio-scsi-pci --virtio0 $datastore:vm-4001-disk-0
qm set 4001 --ide2 $datastore:cloudinit
qm set 4001 --boot c --bootdisk virtio0
qm set 4001 --vga std
qm set 4001 --ostype l26
qm template 4001
sleep 30

# Clone template and create a VM
clear
print_in_box "Creating VM..."
vmid=$(pvesh get /cluster/nextid)
qm clone 4001 $vmid --name $hostname --full
qm set $vmid --cpu host
qm set $vmid --cores $cores
qm set $vmid --memory $memory
qm set $vmid --ciuser $username
qm set $vmid --cipassword $password
if ["ipv6choice" = "n" ]; then
    qm set $vmid --ipconfig0 ip=$ipaddress,gw=$gwaddress
fi
if [ "$ipv6choice" = "y" ]; then
    qm set $vmid --ipconfig0 ip=$ipaddress,gw=$gwaddress,ip6=$ipv6address,gw6=$ipv6gwaddress
fi
qm set $vmid --nameserver $dns
qm set $vmid --searchdomain $domain
if $set_sshkey; then
    qm set $vmid --sshkey $keyfile
fi
qm resize $vmid virtio0 $disk
sleep 5

# Cleanup
clear
print_in_box "Cleaning up..."
rm *.keys
qm destroy 4001
sleep 2

# Print details about the created VM
clear
print_in_box "VM created successfully.
VMID: $vmid
Hostname: $hostname
IP Address: $ipaddress
IPv6 Address: $ipv6address
Username: $username"
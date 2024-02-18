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
print_in_box "Welcome to runbgp & tcude's Proxmox Tools VM creation script!"
sleep 2

print_in_box "Input the ID of the VM you would like to migrate:"
read vm_id

print_in_box "VM $vm_id will be migrated\nEnter the name of the target host that you would like to migrate the VM to. Available hosts:"
ls /etc/pve/nodes
read target_hostname

print_in_box "VM $vm_id will be migrated to $target_hostname\nInput the name of the datastore you would like to migrate to:"
pvesm status
read target_datastore

print_in_box "VM $vm_id will be migrated to $target_hostname on datastore $target_datastore\nProceed? [y/n]"
read -r -p "" response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    print_in_box "Proceeding with the migration of $vm_id to $target_hostname on datastore $target_datastore"
    qm migrate $vm_id $target_hostname --targetstorage $target_datastore &
    process_id=$!
    wait $process_id
    print_in_box "Completed with status $?"
else
    print_in_box "Cancelling."
    exit 1
fi
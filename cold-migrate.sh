#!/bin/bash
echo "###################################"
echo "Welcome to the qm migrate script"
echo -e "################################### \n"
echo "Please start by entering the numerical ID of"
echo -e "the VM you would like to migrate: \n"
read vm_id
echo -e "       \n"
echo -e "VM $vm_id will be migrated \n"
echo "Next, please enter the name of the"
echo "target host that you would like to"
echo -e "migrate the VM to. Your choices are: \n"
ls /etc/pve/nodes
echo -e "       \n"
read target_hostname
echo -e "       \n"
echo -e "VM $vm_id will be migrated to $target_hostname \n"
echo "Lastly, please supply the name of the"
echo -e "datastore you would like to migrate to \n"
pvesm status
echo -e "       \n"
read target_datastore
echo -e "       \n"
echo "To confirm, you will be migrating VM $vm_id to $target_hostname on datastore $target_datastore"
read -r -p "Are you sure? [y/N] " response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
    echo "Proceeding with the migration of $vm_id to $hostname on datastore $target_datastore"
    qm migrate $vm_id $target_hostname --targetstorage $target_datastore &
    process_id=$!
    wait $process_id
    echo "Completed with status $?"
else
    echo "Cancelling"
    exit 1
fi
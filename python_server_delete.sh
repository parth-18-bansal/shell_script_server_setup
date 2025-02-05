#!/bin/bash

# Variables
RESOURCE_GROUP="myResourceGroup"
VM_NAME="myPythonVM"

# Confirm deletion with user
read -p "Are you sure you want to delete the resource group and all associated resources (y/n)? " confirmation

if [[ "$confirmation" != "y" ]]; then
    echo "Aborting deletion."
    exit 1
fi

# Delete the virtual machine
echo "Deleting the virtual machine..."
az vm delete --resource-group $RESOURCE_GROUP --name $VM_NAME --yes --no-wait

# Delete the resource group (this will also delete the VM, Public IP, NSG, etc.)
echo "Deleting the resource group and all associated resources..."
az group delete --name $RESOURCE_GROUP --yes --no-wait

# Optionally, you can clean up other resources like storage accounts, disks, etc., by adding them here.
echo "Cleanup initiated. The resources are being deleted. This may take a few minutes."

# Exit script
exit 0

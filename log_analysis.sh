#!/bin/bash

# Variables
RESOURCE_GROUP="myResourceGroup"
VM_NAME="myPythonVM"
ADMIN_USER="azureuser"
VM_IP="<VM_PUBLIC_IP>"  # Replace this with the actual public IP of your VM
LOG_FILE="vm_logs_$(date +%Y%m%d_%H%M%S).log"
LOCAL_DIR="~/Downloads"  # Replace with the directory where you want to store the logs locally

# SSH into the VM and gather logs
echo "Collecting logs from VM..."

# SSH command to gather system and app logs
ssh -o StrictHostKeyChecking=no $ADMIN_USER@$VM_IP << EOF
    # Create a log file to store the logs
    LOG_PATH="/home/$ADMIN_USER/$LOG_FILE"
    
    echo "System Logs:" > \$LOG_PATH
    echo "=====================" >> \$LOG_PATH
    
    # Collect system logs
    echo "Systemd Logs:" >> \$LOG_PATH
    journalctl -xe >> \$LOG_PATH

    echo "=====================" >> \$LOG_PATH
    echo "Gunicorn Logs:" >> \$LOG_PATH
    sudo journalctl -u gunicorn -f >> \$LOG_PATH

    echo "=====================" >> \$LOG_PATH
    echo "Nginx Logs:" >> \$LOG_PATH
    sudo tail -n 100 /var/log/nginx/error.log >> \$LOG_PATH
    sudo tail -n 100 /var/log/nginx/access.log >> \$LOG_PATH

    echo "=====================" >> \$LOG_PATH
    echo "Application Logs:" >> \$LOG_PATH
    # Assuming your Flask app has some logging file, adjust if necessary
    cat /home/$ADMIN_USER/myapp/app.log >> \$LOG_PATH
    
    echo "=====================" >> \$LOG_PATH
    echo "Firewall Logs:" >> \$LOG_PATH
    sudo ufw status >> \$LOG_PATH
    
    echo "=====================" >> \$LOG_PATH
    echo "Disk Usage Logs:" >> \$LOG_PATH
    df -h >> \$LOG_PATH

    echo "Logs collected into \$LOG_PATH"
EOF

# Download the log file from VM to local machine
echo "Downloading logs to local machine..."

# Using SCP to securely copy the log file to your local machine
scp $ADMIN_USER@$VM_IP:/home/$ADMIN_USER/$LOG_FILE $LOCAL_DIR

# Confirm download
if [[ $? -eq 0 ]]; then
    echo "Logs successfully downloaded to $LOCAL_DIR/$LOG_FILE"
else
    echo "Error: Unable to download logs."
fi

exit 0

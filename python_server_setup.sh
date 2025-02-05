#!/bin/bash

# Variables
RESOURCE_GROUP="myResourceGroup"
LOCATION="eastus"
VM_NAME="myPythonVM"
ADMIN_USER="azureuser"
IMAGE="Canonical:0001-com-ubuntu-server-jammy:22_04-lts-gen2:latest"
SIZE="Standard_B1s"

# Create a resource group
az group create --name $RESOURCE_GROUP --location $LOCATION

# Create a virtual machine
az vm create \
    --resource-group $RESOURCE_GROUP \
    --name $VM_NAME \
    --image $IMAGE \
    --admin-username $ADMIN_USER \
    --generate-ssh-keys \
    --size $SIZE \
    --public-ip-sku Standard

# Get Public IP of the VM
VM_IP=$(az vm list-ip-addresses --resource-group $RESOURCE_GROUP --name $VM_NAME --query "[].virtualMachine.network.publicIpAddresses[0].ipAddress" -o tsv)
echo "VM Public IP: $VM_IP"

# Install necessary packages and deploy app
ssh -o StrictHostKeyChecking=no $ADMIN_USER@$VM_IP << 'EOF'
    # Update system and install dependencies
    sudo apt update && sudo apt upgrade -y
    sudo apt install -y python3 python3-pip python3-venv nginx gunicorn
    
    # Set up the application
    mkdir -p ~/myapp
    cd ~/myapp
    python3 -m venv venv
    source venv/bin/activate
    
    # Create a simple Flask app
    cat > app.py <<EOL
from flask import Flask
app = Flask(__name__)

@app.route('/')
def home():
    return "Hello from Azure VM!"

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
EOL

    # Install dependencies
    pip install flask gunicorn
    
    # Set up Gunicorn
    cat > gunicorn.service <<EOL
[Unit]
Description=Gunicorn instance to serve Python app
After=network.target

[Service]
User=azureuser
Group=www-data
WorkingDirectory=/home/azureuser/myapp
ExecStart=/home/azureuser/myapp/venv/bin/gunicorn --workers 3 --bind unix:/home/azureuser/myapp/app.sock app:app

[Install]
WantedBy=multi-user.target
EOL

    sudo mv gunicorn.service /etc/systemd/system/gunicorn.service
    sudo systemctl start gunicorn
    sudo systemctl enable gunicorn

    # Configure Nginx
    cat > myapp <<EOL
server {
    listen 80;
    server_name $VM_IP;

    location / {
        include proxy_params;
        proxy_pass http://unix:/home/azureuser/myapp/app.sock;
    }
}
EOL

    sudo mv myapp /etc/nginx/sites-available/myapp
    sudo ln -s /etc/nginx/sites-available/myapp /etc/nginx/sites-enabled
    sudo rm /etc/nginx/sites-enabled/default
    sudo systemctl restart nginx

    echo "Deployment completed!"
EOF

echo "Your Python application is live at: http://$VM_IP"

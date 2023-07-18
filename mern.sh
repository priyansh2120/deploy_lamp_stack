#!/bin/bash

# This script is used to configure a MERN stack on a single node
# It deploys a sample application built using MongoDB, Express.js, React, and Node.js

function echo_green() {
    ######################
    # Print in green color
    # Arguments: $1 = string
    ######################

    GREEN='\033[0;32m'
    NC='\033[0m' # No Color

    echo -e "${GREEN}$1 ...${NC}"
}

function echo_red() {
    ######################
    # Print in red color
    # Arguments: $1 = string
    ######################

    RED='\033[0;31m'
    NC='\033[0m' # No Color

    echo -e "${RED}$1 ...${NC}"
}

function checkServiceStatus() {

    #########################
    # Check if service is running
    # Arguments: $1 = service name
    #########################
    service_name=$1
    is_service_running=$(sudo systemctl status $service_name | grep running | wc -l)

    if [ $is_service_running -eq 1 ]; then
        echo_green "$service_name is running"
    else
        echo_red "$service_name is not running"
        exit 1
    fi
}

function isFirewallPortConfigured() {

    #########################
    # Check if firewall port is configured
    # Arguments: $1 = port number
    #########################
    port=$1
    firewalld_ports=$(sudo firewall-cmd --list-all --zone=public | grep ports)

    if [[ $firewalld_ports = *$1* ]]; then
        echo_green "PORT $1 is configured in firewalld"
    else
        echo_red "PORT $1 is not configured in firewalld"
        exit 1
    fi
}

# --------------------------------Database Configuration--------------------------------

# Install and configure MongoDB
echo_green "Installing and configuring MongoDB"
sudo yum install -y mongodb
sudo systemctl start mongodb
sudo systemctl enable mongodb

checkServiceStatus mongodb

# Configure firewall rules for MongoDB
echo_green "Configuring firewall rules for MongoDB"
sudo firewall-cmd --permanent --zone=public --add-port=27017/tcp
sudo firewall-cmd --reload

isFirewallPortConfigured 27017

# --------------------------------Web Server Configuration--------------------------------

# Install Node.js and npm
echo_green "Installing Node.js and npm"
sudo yum install -y nodejs

# Clone the GitHub repository
echo_green "Cloning the GitHub repository"
git clone <repository_url> ~/mern-app
cd ~/mern-app

# Install dependencies for the client (React frontend)
echo_green "Installing client dependencies"
cd client
npm install

# Build the React project
echo_green "Building the React project"
npm run build

# Move the build folder to the server directory
echo_green "Moving build folder to the server directory"
mv build ../server/public

# Navigate to the server directory
cd ../server

# Install dependencies for the server (Express.js backend)
echo_green "Installing server dependencies"
npm install

# Start the server
echo_green "Starting the server"
npm start &

# --------------------------------Reverse Proxy Configuration--------------------------------

# Install and configure Nginx as reverse proxy
echo_green "Installing and configuring Nginx"
sudo yum install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Configure Nginx as reverse proxy for React frontend and Node.js backend
echo_green "Configuring Nginx as reverse proxy"
sudo bash -c 'echo "server {
    listen 80;
    location / {
        root /home/user/mern-app/server/public;
        index index.html index.htm;
        try_files \$uri \$uri/ /index.html;
    }

    location /api {
        proxy_pass http://localhost:3000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}" > /etc/nginx/conf.d/mern-app.conf'

# Reload Nginx configuration
sudo systemctl reload nginx

echo_green "Script executed successfully"

#!/bin/bash

# This script is used to configure LAMP stack on single node
# This script deploys a simple ecommerce application built using PHP and MySQL

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

function checkItemsInWebpage() {

    #########################
    # Check if item is present in webpage
    # Arguments: $1 = webpage, $2 = item
    #########################

    if ([[ $1 = *$2* ]]); then
        echo_green "Webpage is working fine as $2 present on webpage"
    else
        echo_red "Webpage is not working as $2 is not present on webpage"
        exit 1
    fi
}

# --------------------------------Database Configuration--------------------------------

# Install and configure firewalld
echo_green "Installing and configuring firewalld"
sudo yum install -y firewalld
sudo service firewalld start
sudo systemctl enable firewalld

checkServiceStatus firewalld

# Install and Configure Database
echo_green "Installing and configuring Database"
sudo yum install -y mariadb-server
sudo service mariadb start
sudo systemctl enable mariadb

checkServiceStatus firewalld

# Adding firewall rules for database
echo_green "Adding firewall rules for database"
sudo firewall-cmd --permanent --zone=public --add-port=3306/tcp
sudo firewall-cmd --reload

isFirewallPortConfigured 3306

# Creating database and user
echo_green "Creating database and user"
cat >config-db.sql <<-EOF
CREATE DATABASE ecomdb;
CREATE USER 'ecomuser'@'localhost' IDENTIFIED BY 'ecompassword';
GRANT ALL PRIVILEGES ON *.* TO 'ecomuser'@'localhost';
FLUSH PRIVILEGES;
EOF
# eof used for control c to stop writing to file
# we cant directly run command on sql client so we are writing to file and then running it

# Running commands stored in config-db.sql
echo_green "Running commands stored in config-db.sql"
sudo mysql <config-db.sql

# Loading inventory data into database
echo_green "Loading inventory data into database"
cat >db-load-script.sql <<-EOF
USE ecomdb;
CREATE TABLE products (id mediumint(8) unsigned NOT NULL auto_increment,Name varchar(255) default NULL,Price varchar(255) default NULL, ImageUrl varchar(255) default NULL,PRIMARY KEY (id)) AUTO_INCREMENT=1;

INSERT INTO products (Name,Price,ImageUrl) VALUES ("Laptop","100","c-1.png"),("Drone","200","c-2.png"),("VR","300","c-3.png"),("Tablet","50","c-5.png"),("Watch","90","c-6.png"),("Phone Covers","20","c-7.png"),("Phone","80","c-8.png"),("Laptop","150","c-4.png");

EOF
# Running commands stored in db-load-script.sql
echo_green "Running commands stored in db-load-script.sql"
sudo mysql <db-load-script.sql

# my way
mysqlDBResult=$(sudo mysql -e "use ecomdb; select * from products;" | grep Laptop | wc -l)

if [ $mysqlDBResult -eq 2 ]; then
    echo_green "Database configured successfully"
else
    echo_red "Database configuration failed"
    exit 1
fi

# ----------------------------------------Web Server Configuration ----------------------------------------
# install apache web server and php
echo "Installing apache web server and php"
sudo yum install -y httpd php php-mysql

# Adding firewall rules for web server
echo_green "Adding firewall rules for web server"
sudo firewall-cmd --permanent --zone=public --add-port=80/tcp
sudo firewall-cmd --reload

isFirewallPortConfigured 80

# update apache web server configuration file(/etc/httpd/conf/httpd.conf) to use index.php as default page instead of index.html
echo_green "Updating apache web server configuration file"
sudo sed -i 's/index.html/index.php/g' /etc/httpd/conf/httpd.conf

# start and enable apache web server httpd service
echo_green "Starting and enabling apache web server httpd service"
sudo service httpd start
sudo systemctl enable httpd

checkServiceStatus httpd

# install git
echo_green "Installing git"
sudo yum install -y git

# Downloading code from git
echo_green "Downloading code from git"
sudo git clone https://github.com/kodekloudhub/learning-app-ecommerce.git /var/www/html/

# Replace database IP address with localhost in index.php as database is on same server and system is single node
echo_green "Replacing database IP address with localhost in index.php"
sudo sed -i 's/172.20.1.101/localhost/g' /var/www/html/index.php

echo_green "Script executed successfully"

webpage=$(curl http://localhost)

# if space present in any of argument then use double quotes

for item in Laptop Drone VR Tablet Watch "Phone Covers" Phone; do
    checkItemsInWebpage "$webpage" $item
done

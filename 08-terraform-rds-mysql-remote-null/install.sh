#!/bin/bash

# ---------------------------
# Script: install_mysql_amazon_linux.sh
# Purpose: Install MySQL client on Amazon Linux
# ---------------------------
yum install git -y
# Update system packages
echo "[+] Updating system packages..."
sudo yum update -y

# Install MySQL client
echo "[+] Installing MySQL client..."
sudo yum install mysql -y

# Check if installation was successful
echo "[✓] MySQL client installed. Version info:"
mysql --version

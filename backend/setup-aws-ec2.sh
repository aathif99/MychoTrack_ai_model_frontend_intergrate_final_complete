#!/bin/bash
# ==============================================================================
# AWS EC2 Automated Deployment Script for Skin Disease Detection Backend
# Lightweight Backend: Node.js 20 LTS + Local MySQL Server
# Optimized for AWS Free Tier (t2.micro / t3.micro)
# ==============================================================================

set -e

echo "=========================================================="
echo " Starting Automated AWS EC2 Deployment Setup"
echo "=========================================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ------------------------------------------------------------------------------
# STEP 1: Configure Safety 1GB Swap Memory
# ------------------------------------------------------------------------------
echo "[1/5] Checking Swap memory..."
SWAP_EXISTS=$(swapon --show | wc -l)
if [ "$SWAP_EXISTS" -le 1 ]; then
    echo "Creating 1GB safety swapfile..."
    sudo fallocate -l 1G /swapfile || sudo dd if=/dev/zero of=/swapfile bs=1M count=1024
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    sudo sysctl vm.swappiness=10
    echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
    echo "✅ 1GB Swap file successfully created and activated!"
else
    echo "✅ Swap space is already configured."
fi

# ------------------------------------------------------------------------------
# STEP 2: Install System Dependencies & MySQL Server
# ------------------------------------------------------------------------------
echo "[2/5] Updating system packages and installing MySQL Server..."
sudo apt update -y
sudo apt install -y curl wget git build-essential mysql-server

# ------------------------------------------------------------------------------
# STEP 3: Setup Local MySQL Database
# ------------------------------------------------------------------------------
echo "[3/5] Setting up local MySQL database..."
sudo systemctl enable mysql
sudo systemctl start mysql

echo "Configuring database user 'skin_user' and database 'skin_disease_db'..."
sudo mysql -e "CREATE DATABASE IF NOT EXISTS skin_disease_db;"
sudo mysql -e "CREATE USER IF NOT EXISTS 'skin_user'@'localhost' IDENTIFIED BY 'SkinPass123#';"
sudo mysql -e "ALTER USER 'skin_user'@'localhost' IDENTIFIED BY 'SkinPass123#';"
sudo mysql -e "GRANT ALL PRIVILEGES ON skin_disease_db.* TO 'skin_user'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

if [ -f "database/init_aws_mysql.sql" ]; then
    echo "Importing database schema from init_aws_mysql.sql..."
    sudo mysql skin_disease_db < database/init_aws_mysql.sql
    echo "✅ MySQL database and all tables created successfully!"
elif [ -f "database/init.sql" ]; then
    echo "Importing database schema from init.sql..."
    sudo mysql skin_disease_db < database/init.sql
    echo "✅ Database initialized from init.sql!"
fi

# ------------------------------------------------------------------------------
# STEP 4: Install Node.js 20 LTS & PM2
# ------------------------------------------------------------------------------
echo "[4/5] Installing Node.js 20 LTS and PM2..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
fi

echo "Node version: $(node -v)"
echo "NPM version: $(npm -v)"
sudo npm install -g pm2

# ------------------------------------------------------------------------------
# STEP 5: Setup Node.js Backend & Start with PM2
# ------------------------------------------------------------------------------
echo "[5/5] Installing dependencies and starting backend..."
mkdir -p uploads heatmaps profile_picture

if [ -f .env.production ]; then
    cp -f .env.production .env
    echo "✅ Applied local AWS MySQL configuration to .env"
fi

npm install

pm2 delete node-backend 2>/dev/null || true
pm2 delete fastapi-ai 2>/dev/null || true

pm2 start ecosystem.config.js
pm2 save

echo ""
echo "=========================================================="
echo "🎉 DEPLOYMENT COMPLETE! Node.js backend is running on AWS."
echo "=========================================================="
echo "  1. MySQL Database:   Running locally on port 3306"
echo "  2. Node.js Backend:  Running on port 3000"
echo "=========================================================="
pm2 status
echo ""

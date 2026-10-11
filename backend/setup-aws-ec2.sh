#!/bin/bash
# ==============================================================================
# AWS EC2 Automated Deployment Script for Skin Disease Detection Backend
# All-In-One AWS: Node.js + Python FastAPI AI + Local MySQL Server
# Target OS: Ubuntu 22.04 LTS (AWS Free Tier t2.micro / t3.micro)
# ==============================================================================

set -e

echo "=========================================================="
echo " Starting Automated AWS EC2 All-In-One Deployment Setup"
echo "=========================================================="

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# ------------------------------------------------------------------------------
# STEP 1: Configure 4GB Swap Space (CRITICAL FOR AWS FREE TIER 1GB RAM)
# ------------------------------------------------------------------------------
echo "[1/7] Checking Swap memory..."
SWAP_EXISTS=$(swapon --show | wc -l)
if [ "$SWAP_EXISTS" -le 1 ]; then
    echo "Creating 4GB swapfile for TensorFlow / Keras..."
    sudo fallocate -l 4G /swapfile || sudo dd if=/dev/zero of=/swapfile bs=1M count=4096
    sudo chmod 600 /swapfile
    sudo mkswap /swapfile
    sudo swapon /swapfile
    echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab
    sudo sysctl vm.swappiness=10
    echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
    echo "✅ 4GB Swap file successfully created and activated!"
else
    echo "✅ Swap space is already configured."
fi

# ------------------------------------------------------------------------------
# STEP 2: Install System Dependencies
# ------------------------------------------------------------------------------
echo "[2/7] Updating system packages and installing dependencies..."
sudo apt update -y
sudo apt install -y curl wget git build-essential python3 python3-pip python3-venv libgl1 libglib2.0-0 mysql-server

# ------------------------------------------------------------------------------
# STEP 3: Setup Local MySQL Server on AWS EC2
# ------------------------------------------------------------------------------
echo "[3/7] Setting up local MySQL database on AWS..."
sudo systemctl enable mysql
sudo systemctl start mysql

echo "Creating database user 'skin_user' and 'skin_disease_db'..."
sudo mysql -e "CREATE DATABASE IF NOT EXISTS skin_disease_db;"
sudo mysql -e "CREATE USER IF NOT EXISTS 'skin_user'@'localhost' IDENTIFIED BY 'SkinPass123#';"
sudo mysql -e "ALTER USER 'skin_user'@'localhost' IDENTIFIED BY 'SkinPass123#';"
sudo mysql -e "GRANT ALL PRIVILEGES ON skin_disease_db.* TO 'skin_user'@'localhost';"
sudo mysql -e "FLUSH PRIVILEGES;"

if [ -f "database/init_aws_mysql.sql" ]; then
    echo "Importing database schema and data..."
    sudo mysql skin_disease_db < database/init_aws_mysql.sql
    echo "✅ MySQL database and all tables created successfully on AWS!"
elif [ -f "database/init.sql" ]; then
    echo "Importing database schema from init.sql..."
    sudo mysql skin_disease_db < database/init.sql
    echo "✅ Database initialized from init.sql!"
fi

# ------------------------------------------------------------------------------
# STEP 4: Install Node.js 20 LTS & PM2
# ------------------------------------------------------------------------------
echo "[4/7] Installing Node.js 20 LTS and PM2..."
if ! command -v node &> /dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
fi

echo "Node version: $(node -v)"
echo "NPM version: $(npm -v)"
sudo npm install -g pm2

# ------------------------------------------------------------------------------
# STEP 5: Setup Node.js Backend & Environment
# ------------------------------------------------------------------------------
echo "[5/7] Installing backend Node.js packages..."
mkdir -p uploads heatmaps profile_picture

# Apply all-in-one local MySQL production config
if [ -f .env.production ]; then
    cp -f .env.production .env
    echo "✅ Applied local AWS MySQL configuration to .env"
fi

npm install

# ------------------------------------------------------------------------------
# STEP 6: Setup Python Virtual Environment & AI Dependencies
# ------------------------------------------------------------------------------
echo "[6/7] Setting up Python AI service in ai_service/..."
cd "$SCRIPT_DIR/ai_service"

if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

echo "Installing AI Python requirements (FastAPI, TensorFlow, OpenCV)..."
./venv/bin/pip install --upgrade pip
./venv/bin/pip install -r requirements.txt

if [ ! -f "models/skin_classifier.keras" ]; then
    echo "⚠️ WARNING: models/skin_classifier.keras not found!"
else
    echo "✅ AI Model (skin_classifier.keras) verified!"
fi

# ------------------------------------------------------------------------------
# STEP 7: Start All Services with PM2
# ------------------------------------------------------------------------------
echo "[7/7] Starting Node.js and FastAPI services with PM2..."
cd "$SCRIPT_DIR"

pm2 delete node-backend 2>/dev/null || true
pm2 delete fastapi-ai 2>/dev/null || true

pm2 start ecosystem.config.js
pm2 save

echo ""
echo "=========================================================="
echo "🎉 DEPLOYMENT COMPLETE! All services are running on AWS."
echo "=========================================================="
echo "  1. MySQL Database:   Running locally on AWS (port 3306)"
echo "  2. Node.js Backend:  Running on port 3000"
echo "  3. Python AI Model:  Running on port 8000"
echo "=========================================================="
pm2 status
echo ""

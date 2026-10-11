# Complete AWS Free Tier Deployment Guide

This guide walks you step-by-step through deploying your **Node.js Backend**, **Python AI Model Service (FastAPI + TensorFlow)**, and **Database connection** to an **AWS Free Tier EC2 instance**, and configuring your **Flutter mobile app** so any user installing the APK can access the backend from anywhere.

---

## Architecture Overview

```
+--------------------------------------------------------------+
|                    Mobile Phone (Flutter App)                |
|               Installed APK / Physical Device                |
+--------------------------------------------------------------+
                               |
                               | HTTP (Port 3000 / Port 80)
                               v
+--------------------------------------------------------------+
|                  AWS EC2 Free Tier (t2.micro)                |
|              Ubuntu 22.04 LTS | 1 GB RAM + 4 GB Swap         |
|                                                              |
|   +--------------------------+   +-----------------------+   |
|   |   Node.js Express API    |   |  FastAPI AI Service   |   |
|   |       (Port 3000)        |<->|      (Port 8000)      |   |
|   |   Managed by PM2         |   |  Managed by PM2       |   |
|   +--------------------------+   +-----------------------+   |
+--------------------------------------------------------------+
                               |
                               | SSL Connection (Port 3306)
                               v
+--------------------------------------------------------------+
|              Microsoft Azure Database for MySQL              |
|        skindisease-db-dell.mysql.database.azure.com          |
+--------------------------------------------------------------+
```

> **AWS Free Tier 1GB RAM Limitation & The 4GB Swap Solution:**
> AWS `t2.micro` provides only **1 GB of physical RAM**. Loading TensorFlow 2.15 and your 140MB Keras model (`skin_classifier.keras`) requires ~1.2GB–1.6GB memory. Without extra memory, the Linux kernel will terminate the AI process (`Killed`).
>
> We solve this 100% within the Free Tier by configuring a **4 GB Swap File** on your free 30 GB EBS SSD. This gives your EC2 instance **5 GB of effective memory**, allowing both Node.js and TensorFlow to run smoothly with zero extra cost.

---

## Step 1: Create Your Free AWS Account

1. Go to [aws.amazon.com/free](https://aws.amazon.com/free/).
2. Click **Create a Free Account**.
3. Follow the registration steps:
   - Provide email, password, and account name.
   - Choose **Personal** account type.
   - Enter your billing address and credit/debit card (AWS verifies with a temporary ~$1 authorization hold that is refunded).
   - Complete phone verification (SMS/call).
   - Select the **Basic Support (Free)** plan.
4. Log in to the [AWS Management Console](https://console.aws.amazon.com/).

---

## Step 2: Launch an EC2 Free Tier Instance

1. In the AWS Console search bar, type **EC2** and click **EC2**.
2. Click the orange **Launch Instance** button.
3. Configure the following settings:
   - **Name**: `mycotrack-backend`
   - **Application and OS Images (AMI)**: Select **Ubuntu** -> **Ubuntu Server 22.04 LTS (HVM), SSD Volume Type** (Make sure it has the *Free tier eligible* badge).
   - **Instance type**: Choose **t2.micro** (1 vCPU, 1 GiB Memory, *Free tier eligible*). If in a region where `t2.micro` is not available, choose **t3.micro**.
   - **Key pair (login)**:
     - Click **Create new key pair**.
     - Key pair name: `mycotrack-key`.
     - Key pair type: `RSA`.
     - Private key format: `.pem` (for OpenSSH/Mac/Linux/Windows PowerShell).
     - Click **Create key pair** and **save the downloaded `.pem` file safely on your computer**.
   - **Network settings (Firewall / Security Group)**:
     - Check: **Allow SSH traffic from Anywhere (0.0.0.0/0)**.
     - Check: **Allow HTTP traffic from the internet**.
     - Check: **Allow HTTPS traffic from the internet**.
   - **Configure Storage**:
     - Change the root volume size to **30 GiB** (AWS Free Tier provides up to 30 GiB of General Purpose SSD (gp3/gp2) for free).
4. Click **Launch Instance**.
5. Click **View all instances** and wait until the **Instance state** changes to **Running**.

---

## Step 3: Open Port 3000 in Security Group

Your Node.js API runs on port 3000. You must allow incoming traffic to port 3000 so the mobile app can reach it:

1. Click on your running instance.
2. In the bottom tabs, click **Security**.
3. Click the link under **Security groups** (e.g., `launch-wizard-1`).
4. Click **Edit inbound rules**.
5. Click **Add rule**:
   - **Type**: Custom TCP
   - **Port range**: `3000`
   - **Source**: `Anywhere-IPv4` (`0.0.0.0/0`)
   - **Description**: `Node.js Backend API`
6. Click **Save rules**.

---

## Step 4: Connect to Your EC2 Instance

You have two easy ways to connect:

### Option A: Using AWS Browser Terminal (Easiest)
1. Select your instance in the EC2 Console.
2. Click the **Connect** button at the top.
3. Choose the **EC2 Instance Connect** tab.
4. Click **Connect**. A terminal window opens directly in your browser.

### Option B: Using Windows PowerShell
Open PowerShell in the folder where your `mycotrack-key.pem` is saved:
```powershell
ssh -i "mycotrack-key.pem" ubuntu@<YOUR_EC2_PUBLIC_IP>
```

---

## Step 5: Transfer the Backend Code to EC2

On your Windows computer, open PowerShell in `c:\Users\DELL\Desktop\AWS`:

1. Zip the backend folder (excluding `node_modules` and Python `venv`):
   ```powershell
   Compress-Archive -Path backend\* -DestinationPath backend_aws.zip -Force
   ```
2. Upload the zip file to your EC2 instance using `scp`:
   ```powershell
   scp -i "path\to\mycotrack-key.pem" backend_aws.zip ubuntu@<YOUR_EC2_PUBLIC_IP>:~/
   ```
3. In your EC2 terminal, unzip the files:
   ```bash
   sudo apt install -y unzip
   mkdir -p ~/backend
   unzip ~/backend_aws.zip -d ~/backend
   cd ~/backend
   ```

---

## Step 6: Run the One-Click Automated Deployment Script

Once inside `~/backend` on your EC2 instance, make the setup script executable and run it:

```bash
chmod +x setup-aws-ec2.sh
./setup-aws-ec2.sh
```

### What this script automatically handles:
1. **Creates a 4GB Swap Space** (enables TensorFlow to load without OOM crashes on `t2.micro`).
2. **Installs Node.js 20 LTS, npm, and PM2**.
3. **Installs Python 3, venv, and system libraries for OpenCV** (`libgl1`, `libglib2.0-0`).
4. **Installs Node.js npm packages**.
5. **Creates the Python virtual environment and installs all AI requirements** (`FastAPI`, `Uvicorn`, `TensorFlow`, `Keras`, `OpenCV`).
6. **Launches both services under PM2** so they run 24/7 in the background and automatically restart if the server reboots.

### Check Service Status on EC2:
```bash
pm2 status
```
Both `node-backend` and `fastapi-ai` should show status **online**.

You can also test the API locally on EC2:
```bash
curl http://localhost:3000/
# Output: {"message":"Skin Disease Detection API is running"}
```

---

## Step 7: Update Mobile App Configuration

In your local project on your computer:

1. Copy your EC2 instance's **Public IPv4 address** from the AWS EC2 Console (e.g., `3.85.123.45`).
2. Open `lib/services/api_config.dart`.
3. Replace `'http://YOUR_AWS_EC2_PUBLIC_IP:3000'` with your actual EC2 address:
   ```dart
   static const String awsServerUrl = 'http://3.85.123.45:3000';
   static const bool useAwsCloud = true;
   ```

All app screens (`login_screen.dart`, `create_new_account_screen.dart`, and auth screens) are now unified to automatically use `ApiConfig.baseUrl`.

---

## Step 8: Build and Install the Mobile App APK

Now build the production Android APK:

```bash
flutter build apk --release
```

The compiled APK will be created at:
```
build/app/outputs/flutter-apk/app-release.apk
```

You can now send `app-release.apk` to any Android phone, install it, and use the app. It will seamlessly communicate with your AWS EC2 backend and Azure MySQL database over the internet!

---

## Useful Maintenance Commands on EC2

| Command | Purpose |
| :--- | :--- |
| `pm2 status` | Check if Node.js and AI services are running |
| `pm2 logs` | View live real-time logs from both services |
| `pm2 logs node-backend` | View only Node.js backend logs |
| `pm2 logs fastapi-ai` | View only AI model FastAPI logs |
| `pm2 restart all` | Restart both services |
| `free -h` | View RAM and Swap memory usage |
| `htop` | View CPU and process memory utilization |

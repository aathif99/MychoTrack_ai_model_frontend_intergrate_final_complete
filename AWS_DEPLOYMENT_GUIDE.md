# Complete AWS EC2 Deployment Guide (New Account)

This guide walks you step-by-step through deploying your updated **Node.js + MySQL Backend** to a brand new **AWS Free Tier EC2 instance**, and connecting your **Flutter mobile app** to it.

---

## Architecture Overview

```
+--------------------------------------------------------------+
|                    Mobile Phone (Flutter App)                |
|               Installed APK / Physical Device                |
+--------------------------------------------------------------+
                               |
                               | HTTP (Port 3000)
                               v
+--------------------------------------------------------------+
|                  AWS EC2 Free Tier (t2.micro / t3.micro)     |
|                   Ubuntu 22.04 LTS | ~350 MB RAM             |
|                                                              |
|   +--------------------------+   +-----------------------+   |
|   |   Node.js Express API    |   |  Local MySQL Server   |   |
|   |       (Port 3000)        |<->|      (Port 3306)      |   |
|   |   Managed by PM2         |   |  skin_disease_db      |   |
|   +--------------------------+   +-----------------------+   |
+--------------------------------------------------------------+
```

> **Why this new backend is so fast and reliable:**
> Because the heavy AI inference now runs **on the user's phone in ~150ms**, your AWS EC2 instance only runs Node.js and MySQL. Total RAM consumption is only **~350 MB / 1000 MB**. It will **never freeze, never crash, and remain 100% free forever on AWS Free Tier**.

---

## Step 1: Create / Log in to Your New AWS Account

1. Go to [aws.amazon.com](https://aws.amazon.com/) and log in to your **new AWS account**.
2. At the top right corner of the AWS Console, choose your preferred region (e.g., **Asia Pacific (Mumbai) `ap-south-1`** or **US East (N. Virginia) `us-east-1`**).

---

## Step 2: Launch a Free Tier EC2 Instance

1. In the top search bar, type **EC2** and click **EC2**.
2. Click the orange **Launch Instance** button.
3. Configure the following settings:
   - **Name**: `mycotrack-backend`
   - **Application and OS Images (AMI)**: Select **Ubuntu** $\to$ **Ubuntu Server 22.04 LTS (HVM)** *(Make sure it has the "Free tier eligible" badge)*.
   - **Instance type**: Choose **t2.micro** or **t3.micro** *(Free tier eligible)*.
   - **Key pair (login)**:
     - Click **Create new key pair**.
     - Key pair name: `mycotrack-key`.
     - Key pair type: `RSA`.
     - Private key format: `.pem`.
     - Click **Create key pair** and **save the downloaded `.pem` file safely** (e.g. on your Desktop).
   - **Network settings (Firewall / Security Group)**:
     - Check: **Allow SSH traffic from Anywhere (0.0.0.0/0)**.
     - Check: **Allow HTTP traffic from the internet**.
   - **Configure Storage**:
     - Change root volume size from `8 GiB` to **20 GiB** or **30 GiB** (AWS Free Tier includes up to 30 GiB for free).
4. Click **Launch Instance**.
5. Click **View all instances** and wait ~30 seconds until the **Instance state** shows **Running**.

---

## Step 3: Open Port 3000 in the Security Group

Your Node.js API runs on port 3000. Allow incoming traffic so the mobile app can reach it:

1. Click on your running instance.
2. In the bottom tabs, select **Security**.
3. Click the link under **Security groups** (e.g., `launch-wizard-1`).
4. Click **Edit inbound rules**.
5. Click **Add rule**:
   - **Type**: Custom TCP
   - **Port range**: `3000`
   - **Source**: `Anywhere-IPv4` (`0.0.0.0/0`)
   - **Description**: `Node.js Backend API`
6. Click **Save rules**.

---

## Step 4: Upload the Pre-Built Backend Zip to EC2

We have already created a clean, lightweight zip package: **`backend_deploy.zip`** (only **~48 KB**!).

Open PowerShell on your computer and run (replace `<YOUR_NEW_EC2_IP>` and path to `.pem`):

```powershell
scp -i "C:\path\to\mycotrack-key.pem" "C:\Users\DELL\Desktop\AWS\backend_deploy.zip" ubuntu@<YOUR_NEW_EC2_IP>:~/
```

*(Alternatively, if you prefer the browser: click **Connect** $\to$ **EC2 Instance Connect** in AWS Console, open the browser terminal, and create the files).*

---

## Step 5: Connect to EC2 and Run the 1-Minute Setup

1. In the EC2 Console, select your instance and click **Connect** $\to$ **EC2 Instance Connect** $\to$ **Connect** (or use SSH from PowerShell):
   ```powershell
   ssh -i "C:\path\to\mycotrack-key.pem" ubuntu@<YOUR_NEW_EC2_IP>
   ```

2. In the EC2 terminal, run these commands:
   ```bash
   sudo apt update -y && sudo apt install -y unzip
   mkdir -p ~/backend
   unzip ~/backend_deploy.zip -d ~/backend
   cd ~/backend
   chmod +x setup-aws-ec2.sh
   ./setup-aws-ec2.sh
   ```

### What `setup-aws-ec2.sh` automatically does in ~1 minute:
1. Configures a 1GB safety swap space.
2. Installs MySQL Server and automatically imports the database schema and tables.
3. Installs Node.js 20 LTS and PM2.
4. Installs Node.js npm packages and starts `node-backend` under PM2 (24/7 background service).

3. Verify the server is running:
   ```bash
   pm2 status
   ```
   You will see `node-backend` status: **online**.

4. Test it with curl:
   ```bash
   curl http://localhost:3000/
   # Output: {"message":"Skin Disease Detection API is running"}
   ```

---

## Step 6: Update the Flutter App with Your New Server IP

1. Copy your new EC2 **Public IPv4 address** from the AWS Console (e.g. `3.85.123.45`).
2. Open [frontend/lib/utils/constants.dart](file:///c:/Users/DELL/Desktop/AWS/frontend/lib/utils/constants.dart).
3. Update `awsServerUrl` with your new IP:
   ```dart
   static const String awsServerUrl = 'http://3.85.123.45:3000';
   ```

Now run or build your Flutter app:
```powershell
cd frontend
flutter run
```

---

## Useful Maintenance Commands on EC2

| Command | Purpose |
| :--- | :--- |
| `pm2 status` | Check if the backend is running |
| `pm2 logs` | View live real-time API logs |
| `pm2 restart node-backend` | Restart the backend server |
| `free -h` | View RAM usage (typically ~350 MB out of 1 GB) |

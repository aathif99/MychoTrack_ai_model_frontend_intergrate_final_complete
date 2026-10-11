#!/bin/bash
sudo mysql << 'EOF'
CREATE DATABASE IF NOT EXISTS skin_disease_db;
CREATE USER IF NOT EXISTS 'skin_user'@'%' IDENTIFIED BY 'SkinPass123';
ALTER USER 'skin_user'@'%' IDENTIFIED BY 'SkinPass123';
CREATE USER IF NOT EXISTS 'skin_user'@'localhost' IDENTIFIED BY 'SkinPass123';
ALTER USER 'skin_user'@'localhost' IDENTIFIED BY 'SkinPass123';
CREATE USER IF NOT EXISTS 'skin_user'@'127.0.0.1' IDENTIFIED BY 'SkinPass123';
ALTER USER 'skin_user'@'127.0.0.1' IDENTIFIED BY 'SkinPass123';
GRANT ALL PRIVILEGES ON skin_disease_db.* TO 'skin_user'@'%';
GRANT ALL PRIVILEGES ON skin_disease_db.* TO 'skin_user'@'localhost';
GRANT ALL PRIVILEGES ON skin_disease_db.* TO 'skin_user'@'127.0.0.1';
FLUSH PRIVILEGES;
EOF

sed -i 's/DB_PASSWORD=.*/DB_PASSWORD="SkinPass123"/g' /home/ubuntu/backend/.env
sed -i 's/DB_PASSWORD=.*/DB_PASSWORD="SkinPass123"/g' /home/ubuntu/backend/.env.production

if [ -f /home/ubuntu/backend/database/init_aws_mysql.sql ]; then
    sudo mysql skin_disease_db < /home/ubuntu/backend/database/init_aws_mysql.sql
    echo "Database imported successfully!"
fi

cd /home/ubuntu/backend
pm2 restart node-backend --update-env
echo "node-backend restarted with clean password!"

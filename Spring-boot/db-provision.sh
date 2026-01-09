#!/bin/bash

sudo apt update -y
sudo apt install mysql-server -y

sudo sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql

sudo mysql <<EOF
CREATE DATABASE library;
CREATE USER 'library_user'@'%' IDENTIFIED BY 'library_pass';
GRANT ALL PRIVILEGES ON library.* TO 'library_user'@'%';
FLUSH PRIVILEGES;
EOF

cd /home/ubuntu
git clone YOUR_GITHUB_REPO_URL
cd YOUR_REPO_NAME
sudo mysql library < library.sql

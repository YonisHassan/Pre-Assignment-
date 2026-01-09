#!/bin/bash

DB_IP="PUT_DB_PRIVATE_IP_HERE"

sudo apt update -y
sudo apt install openjdk-17-jdk maven git -y

cd /home/ubuntu
git clone YOUR_GITHUB_REPO_URL
cd YOUR_REPO_NAME/ProjectLibrary2

cat > src/main/resources/application.properties <<EOF
spring.datasource.url=jdbc:mysql://${DB_IP}:3306/library
spring.datasource.username=library_user
spring.datasource.password=library_pass
spring.jpa.hibernate.ddl-auto=validate
server.port=5000
EOF

mvn clean package -DskipTests
java -jar target/*.jar

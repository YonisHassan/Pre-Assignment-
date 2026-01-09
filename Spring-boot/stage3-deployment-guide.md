# Stage 3: AWS EC2 2-Tier Deployment - Documentation

## Overview

This stage deploys a Java Spring Boot application and MySQL database on separate AWS EC2 instances, demonstrating a classic 2-tier architecture.

### Architecture
```
┌─────────────────┐         ┌─────────────────┐
│   App VM        │────────▶│   DB VM         │
│ (Spring Boot)   │         │   (MySQL)       │
│ Port 5000       │         │   Port 3306     │
│ Public Access   │         │   Private Only  │
└─────────────────┘         └─────────────────┘
```

---

## EC2 Instance Requirements

### Database VM
- **Instance Type**: t3.micro or t3a.micro (1GB RAM minimum)
- **OS**: Ubuntu 22.04 LTS
- **Storage**: 8GB minimum
- **Security Group Inbound Rules**:
  - Port 22 (SSH): `0.0.0.0/0`
  - Port 3306 (MySQL): `<APP_PRIVATE_IP>/32`

### Application VM  
- **Instance Type**: t3.small (2GB RAM minimum)
- **OS**: Ubuntu 22.04 LTS
- **Storage**: 8GB minimum
- **Security Group Inbound Rules**:
  - Port 22 (SSH): `0.0.0.0/0`
  - Port 5000 (Application): `0.0.0.0/0`

---

## Database VM Setup

### 1. Install and Configure MySQL

```bash
# Update system
sudo apt update -y

# Install MySQL Server
sudo apt install mysql-server -y

# Configure MySQL to accept remote connections
sudo sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf

# Restart MySQL to apply changes
sudo systemctl restart mysql

# Verify MySQL is listening on all interfaces
ss -tuln | grep 3306
# Should show: 0.0.0.0:3306
```

### 2. Create Database and User

```bash
sudo mysql <<EOF
CREATE DATABASE library;
CREATE USER 'library_user'@'%' IDENTIFIED BY 'library_pass';
GRANT ALL PRIVILEGES ON library.* TO 'library_user'@'%';
FLUSH PRIVILEGES;
EXIT;
EOF
```

### 3. Seed the Database

```bash
# Navigate to where your library.sql file is located
cd /path/to/your/repo

# Seed the database
sudo mysql library < library.sql

# Verify data was loaded
sudo mysql -e "USE library; SELECT * FROM authors;"
```

**Expected Output:**
```
+-----------+---------------------+
| author_id | full_name           |
+-----------+---------------------+
|         1 | Phil                |
|         2 | William Shakespeare |
|         3 | Jane Austen         |
|         4 | Charles Dickens     |
+-----------+---------------------+
```

### 4. Get Database Private IP

```bash
hostname -I
# Example output: 172.31.38.43
# Save this IP - you'll need it for the App VM configuration
```

---

## Application VM Setup

### 1. Install Dependencies

```bash
# Update system
sudo apt update -y

# Install Java 17 and Maven
sudo apt install openjdk-17-jdk maven git -y

# Verify installations
java -version
mvn -version
```

### 2. Configure Application

```bash
# Navigate to your project directory
cd ~/path/to/ProjectLibrary2

# Create application.properties with database connection details
# REPLACE 'DB_PRIVATE_IP' with the actual private IP from the DB VM
cat > src/main/resources/application.properties << 'EOF'
spring.datasource.url=jdbc:mysql://DB_PRIVATE_IP:3306/library
spring.datasource.username=library_user
spring.datasource.password=library_pass
spring.jpa.hibernate.ddl-auto=validate
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.MySQLDialect
server.port=5000
EOF
```

**Example with actual IP:**
```properties
spring.datasource.url=jdbc:mysql://172.31.38.43:3306/library
spring.datasource.username=library_user
spring.datasource.password=library_pass
spring.jpa.hibernate.ddl-auto=validate
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.MySQLDialect
server.port=5000
```

### 3. Test Database Connectivity

```bash
# Install netcat if not already installed
sudo apt install netcat -y

# Test connection to database (replace with your DB private IP)
nc -zv 172.31.38.43 3306

# Expected output: "Connection to 172.31.38.43 3306 port [tcp/mysql] succeeded!"
```

### 4. Build and Run Application

```bash
# Clean previous builds and package application
mvn clean package -DskipTests

# Run the application
java -jar target/*.jar
```

**Expected Output:**
```
...
Tomcat initialized with port(s): 5000 (http)
...
Started LibraryProject2Application in X seconds
```

---

## Testing the Deployment

### Web UI Access

1. Open browser to: `http://<APP_PUBLIC_IP>:5000/web/authors`
   - Example: `http://108.130.203.236:5000/web/authors`

2. You should see a list of 4 authors:
   - Phil
   - William Shakespeare
   - Jane Austen
   - Charles Dickens

### API Access

1. Open browser to: `http://<APP_PUBLIC_IP>:5000/authors`

2. You should see JSON response:
```json
[
  {"author_id": 1, "full_name": "Phil"},
  {"author_id": 2, "full_name": "William Shakespeare"},
  {"author_id": 3, "full_name": "Jane Austen"},
  {"author_id": 4, "full_name": "Charles Dickens"}
]
```

### View Specific Author

- URL: `http://<APP_PUBLIC_IP>:5000/web/author/3`
- Should display: Jane Austen

---

## Troubleshooting Guide

### Issue 1: Can't Connect to Database

**Symptoms:**
- App shows: `Communications link failure`
- Or: `Connection timed out`

**Solutions:**

1. **Check MySQL is listening on 0.0.0.0:**
   ```bash
   # On DB VM
   ss -tuln | grep 3306
   # Must show: 0.0.0.0:3306 (NOT 127.0.0.1:3306)
   ```

2. **Fix MySQL bind address if needed:**
   ```bash
   sudo sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
   sudo systemctl restart mysql
   ```

3. **Verify Security Group allows port 3306:**
   - Go to AWS Console → EC2 → DB Instance → Security tab
   - Check inbound rules include: Port 3306 from App VM's private IP

4. **Test connectivity from App VM:**
   ```bash
   nc -zv <DB_PRIVATE_IP> 3306
   ```

### Issue 2: App Hangs During Startup

**Symptoms:**
- App shows logs but never completes startup
- Stuck at "Processing PersistenceUnitInfo" or similar Hibernate messages

**Solutions:**

1. **Use correct ddl-auto setting:**
   ```properties
   spring.jpa.hibernate.ddl-auto=validate
   # NOT: update, create, or create-drop
   ```

2. **Ensure database is seeded BEFORE starting app:**
   ```bash
   sudo mysql library < library.sql
   ```

3. **Kill any hanging Java processes:**
   ```bash
   pkill -9 java
   ```

4. **Use JAR execution instead of maven:**
   ```bash
   # Don't use: mvn spring-boot:run (too slow)
   # Use: java -jar target/*.jar (faster, more reliable)
   ```

### Issue 3: Port 5000 Not Accessible

**Symptoms:**
- Browser shows "Unable to connect"
- curl returns connection refused

**Solutions:**

1. **Check Security Group has port 5000 open:**
   - AWS Console → EC2 → App Instance → Security tab
   - Inbound rules must include: Port 5000 from 0.0.0.0/0

2. **Verify app is running:**
   ```bash
   ps aux | grep java
   ss -tuln | grep 5000
   ```

3. **Check app logs for errors:**
   ```bash
   # If app is in foreground, check terminal output
   # Look for: "Tomcat started on port(s): 5000"
   ```

### Issue 4: Database Authentication Failed

**Symptoms:**
- `Access denied for user 'library_user'@'hostname'`

**Solutions:**

1. **Recreate database user:**
   ```bash
   sudo mysql -e "DROP USER IF EXISTS 'library_user'@'%'; CREATE USER 'library_user'@'%' IDENTIFIED BY 'library_pass'; GRANT ALL PRIVILEGES ON library.* TO 'library_user'@'%'; FLUSH PRIVILEGES;"
   ```

2. **Verify credentials in application.properties match database user**

---

## Quick Deployment Scripts

### Complete DB VM Setup Script

```bash
#!/bin/bash
# Save as: db-setup.sh

# Update and install MySQL
sudo apt update -y
sudo apt install mysql-server -y

# Configure remote access
sudo sed -i 's/bind-address.*/bind-address = 0.0.0.0/' /etc/mysql/mysql.conf.d/mysqld.cnf
sudo systemctl restart mysql

# Create database and user
sudo mysql <<EOF
CREATE DATABASE library;
CREATE USER 'library_user'@'%' IDENTIFIED BY 'library_pass';
GRANT ALL PRIVILEGES ON library.* TO 'library_user'@'%';
FLUSH PRIVILEGES;
EOF

# Seed database (adjust path as needed)
sudo mysql library < /home/ubuntu/library.sql

echo "Database setup complete!"
echo "Private IP: $(hostname -I | awk '{print $1}')"
```

### Complete App VM Setup Script

```bash
#!/bin/bash
# Save as: app-setup.sh
# EDIT THE DB_IP VARIABLE BELOW

DB_IP="172.31.38.43"  # CHANGE THIS TO YOUR DB PRIVATE IP

# Install dependencies
sudo apt update -y
sudo apt install openjdk-17-jdk maven -y

# Navigate to project
cd ~/ProjectLibrary2

# Configure application
cat > src/main/resources/application.properties <<EOF
spring.datasource.url=jdbc:mysql://${DB_IP}:3306/library
spring.datasource.username=library_user
spring.datasource.password=library_pass
spring.jpa.hibernate.ddl-auto=validate
spring.jpa.properties.hibernate.dialect=org.hibernate.dialect.MySQLDialect
server.port=5000
EOF

# Build and run
mvn clean package -DskipTests
java -jar target/*.jar
```

---

## Key Learnings

### What Works
✅ **Use compiled JAR**: `java -jar target/*.jar` is faster and more reliable than `mvn spring-boot:run`

✅ **Seed database first**: Always populate the database before starting the application

✅ **Use application.properties**: More reliable than environment variables for Spring Boot

✅ **Use private IPs**: Database connection should use the DB VM's private IP, not public

✅ **Validate schema only**: `spring.jpa.hibernate.ddl-auto=validate` prevents startup hangs

✅ **Test connectivity**: Use `nc -zv` to verify network connectivity before debugging application issues

### What Doesn't Work
❌ **Don't use mvn spring-boot:run**: Too slow, can have class loading issues

❌ **Don't use ddl-auto=update**: Causes Hibernate to hang during startup

❌ **Don't use environment variables alone**: Spring Boot doesn't reliably read them

❌ **Don't forget security groups**: Most connectivity issues are security group misconfigurations

❌ **Don't seed after app starts**: Database must be populated before application startup

---

## Architecture Diagram

```
Internet
    │
    │ HTTP (Port 5000)
    │
    ▼
┌─────────────────────────────────┐
│     Application VM              │
│  ┌───────────────────────────┐  │
│  │   Spring Boot App         │  │
│  │   Java 17 + Maven         │  │
│  │   Port: 5000              │  │
│  └───────────────────────────┘  │
│         Public IP               │
│         Private IP: 172.31.X.X  │
└─────────────────────────────────┘
            │
            │ JDBC/MySQL (Port 3306)
            │ Private Network
            ▼
┌─────────────────────────────────┐
│     Database VM                 │
│  ┌───────────────────────────┐  │
│  │   MySQL Server            │  │
│  │   Database: library       │  │
│  │   Port: 3306              │  │
│  └───────────────────────────┘  │
│         Private IP: 172.31.X.X  │
└─────────────────────────────────┘

Security Groups:
- App VM: Allow 22, 5000 from 0.0.0.0/0
- DB VM: Allow 22 from 0.0.0.0/0, 3306 from App VM only
```

---

## Next Steps

Stage 3 is now complete. You can proceed to:
- **Stage 4**: Deploy using Docker Compose on a single VM
- **Stage 5**: Deploy using Kubernetes (Minikube) on a single VM

---

## Time Spent
- **Target**: 1 day
- **Actual**: Too fucking long
- **Main blockers**: Security groups, Hibernate configuration, Maven vs JAR execution

---

## Resources
- [Spring Boot Documentation](https://docs.spring.io/spring-boot/docs/current/reference/html/)
- [MySQL Remote Access](https://dev.mysql.com/doc/refman/8.0/en/remote-access.html)
- [AWS EC2 Security Groups](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html)

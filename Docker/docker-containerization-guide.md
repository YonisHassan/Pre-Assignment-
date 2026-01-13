# Docker Containerization Guide

A comprehensive guide to containerizing applications with Docker and Docker Compose.

## Table of Contents

- [Overview](#overview)
- [Basic Concepts](#basic-concepts)
- [Getting Started](#getting-started)
- [Dockerfile Guide](#dockerfile-guide)
- [Docker Compose Guide](#docker-compose-guide)
- [Common Application Examples](#common-application-examples)
- [Docker Compose Reference](#docker-compose-reference)
- [Common Commands](#common-commands)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

---

## Overview

Containerization packages your application with all its dependencies into a portable, isolated unit that runs consistently across different environments.

### Benefits

- **Consistency**: Works the same everywhere (dev, staging, production)
- **Isolation**: Each container runs independently
- **Portability**: Run anywhere Docker is installed
- **Efficiency**: Lightweight compared to virtual machines
- **Scalability**: Easy to scale horizontally

---

## Basic Concepts

| Term | Definition |
|------|------------|
| **Container** | A lightweight, isolated environment running your app |
| **Image** | A blueprint/template for creating containers |
| **Dockerfile** | Instructions for building an image |
| **docker-compose.yml** | Configuration file for running multiple containers together |
| **Volume** | Persistent storage for container data |
| **Network** | Communication channel between containers |

---

## Getting Started

### Prerequisites

Install Docker and Docker Compose:

```bash
# Verify installation
docker --version
docker-compose --version
```

### Basic Workflow

1. **Write Dockerfile** → Build instructions for your app
2. **Write docker-compose.yml** → Orchestrate multiple services
3. **Run `docker-compose up --build`** → Build and start everything
4. **Access your app** → Via localhost:PORT
5. **Make changes** → Rebuild with `docker-compose up --build`
6. **Clean up** → `docker-compose down -v`

---

## Dockerfile Guide

The Dockerfile defines how to build your application image.

**Location:** Place in your application's root directory

### Basic Structure

```dockerfile
# 1. Choose base image (includes runtime environment)
FROM <base-image>:<version>

# 2. Set working directory inside container
WORKDIR /app

# 3. Copy dependency files first (for caching)
COPY <dependency-files> .

# 4. Install dependencies
RUN <install-command>

# 5. Copy application source code
COPY . .

# 6. Build application (if needed)
RUN <build-command>

# 7. Expose port (documentation only)
EXPOSE <port>

# 8. Define startup command
CMD ["<command>", "arg1", "arg2"]
```

### Common Dockerfile Instructions

| Instruction | Purpose | Example |
|-------------|---------|---------|
| `FROM` | Set base image | `FROM node:18-alpine` |
| `WORKDIR` | Set working directory | `WORKDIR /app` |
| `COPY` | Copy files to container | `COPY . .` |
| `RUN` | Execute commands during build | `RUN npm install` |
| `EXPOSE` | Document port (metadata) | `EXPOSE 8080` |
| `CMD` | Default command to run | `CMD ["npm", "start"]` |
| `ENTRYPOINT` | Configure executable | `ENTRYPOINT ["python"]` |
| `ENV` | Set environment variables | `ENV NODE_ENV=production` |
| `ARG` | Build-time variables | `ARG VERSION=1.0` |
| `VOLUME` | Create mount point | `VOLUME /data` |

### Dockerfile Best Practices

```dockerfile
# Use specific versions, not 'latest'
FROM node:18-alpine

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001

# Install dependencies as separate layer (better caching)
COPY package*.json ./
RUN npm ci --only=production

# Copy source code
COPY --chown=nodejs:nodejs . .

# Switch to non-root user
USER nodejs

# Use exec form for CMD (better signal handling)
CMD ["node", "server.js"]
```

---

## Docker Compose Guide

Docker Compose orchestrates multiple services (app, database, cache, etc.)

**Location:** Place in project root directory

### Basic Structure

```yaml
version: '3.8'

services:
  # Service 1: Your application
  app:
    build: .                    # Build from Dockerfile in current directory
    # OR
    # image: your-image:tag     # Use pre-built image
    container_name: my-app
    ports:
      - "HOST_PORT:CONTAINER_PORT"
    environment:
      - ENV_VAR_NAME=value
    depends_on:
      - database
    volumes:
      - ./local-path:/container-path
    restart: unless-stopped

  # Service 2: Database (example)
  database:
    image: postgres:15
    container_name: my-database
    environment:
      - POSTGRES_DB=mydb
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
    ports:
      - "5432:5432"
    volumes:
      - db-data:/var/lib/postgresql/data

# Named volumes (persisted data)
volumes:
  db-data:
```

### Key docker-compose.yml Options

| Option | Purpose | Example |
|--------|---------|---------|
| `build` | Build image from Dockerfile | `build: .` or `build: ./path` |
| `image` | Use pre-built image | `image: nginx:latest` |
| `ports` | Expose ports | `- "8080:80"` |
| `environment` | Set env variables | `- NODE_ENV=production` |
| `volumes` | Mount storage | `- ./data:/app/data` |
| `depends_on` | Service dependencies | `depends_on: - db` |
| `networks` | Custom networking | `networks: - backend` |
| `restart` | Restart policy | `restart: always` |
| `command` | Override CMD | `command: npm start` |
| `healthcheck` | Health monitoring | `test: ["CMD", "curl", "..."]` |

---

## Common Application Examples

### Node.js Application

**Dockerfile:**

```dockerfile
FROM node:18-alpine

WORKDIR /app

# Copy dependency files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy source code
COPY . .

# Expose port
EXPOSE 3000

# Start application
CMD ["npm", "start"]
```

**docker-compose.yml:**

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=mongodb://mongo:27017/myapp
    depends_on:
      - mongo
    volumes:
      - ./src:/app/src  # For hot reload in development

  mongo:
    image: mongo:6
    volumes:
      - mongo-data:/data/db
    ports:
      - "27017:27017"
    environment:
      - MONGO_INITDB_ROOT_USERNAME=admin
      - MONGO_INITDB_ROOT_PASSWORD=password

volumes:
  mongo-data:
```

### Python Flask Application

**Dockerfile:**

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Copy requirements
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

EXPOSE 5000

CMD ["python", "app.py"]
```

**docker-compose.yml:**

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "5000:5000"
    environment:
      - FLASK_ENV=production
      - DATABASE_URL=postgresql://user:pass@postgres:5432/dbname
    depends_on:
      postgres:
        condition: service_healthy
    volumes:
      - ./app:/app  # For development

  postgres:
    image: postgres:15
    environment:
      - POSTGRES_DB=dbname
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
    volumes:
      - pg-data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:alpine
    ports:
      - "6379:6379"

volumes:
  pg-data:
```

### Java Spring Boot Application

**Dockerfile:**

```dockerfile
# Build stage
FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /app

# Copy pom.xml and download dependencies
COPY pom.xml .
RUN mvn dependency:go-offline

# Copy source and build
COPY src ./src
RUN mvn package -DskipTests

# Runtime stage
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

# Copy jar from build stage
COPY --from=build /app/target/*.jar app.jar

EXPOSE 8080

CMD ["java", "-jar", "app.jar"]
```

**docker-compose.yml:**

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "8080:8080"
    environment:
      - SPRING_DATASOURCE_URL=jdbc:mysql://mysql:3306/mydb
      - SPRING_DATASOURCE_USERNAME=user
      - SPRING_DATASOURCE_PASSWORD=password
      - SPRING_JPA_HIBERNATE_DDL_AUTO=update
    depends_on:
      mysql:
        condition: service_healthy

  mysql:
    image: mysql:8.0
    environment:
      - MYSQL_DATABASE=mydb
      - MYSQL_USER=user
      - MYSQL_PASSWORD=password
      - MYSQL_ROOT_PASSWORD=rootpass
    ports:
      - "3306:3306"
    volumes:
      - mysql-data:/var/lib/mysql
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

volumes:
  mysql-data:
```

### React Application (with Nginx)

**Dockerfile:**

```dockerfile
# Build stage
FROM node:18-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .
RUN npm run build

# Production stage
FROM nginx:alpine

COPY --from=build /app/build /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

**nginx.conf:**

```nginx
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

**docker-compose.yml:**

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "80:80"
    restart: unless-stopped
```

### Django Application

**Dockerfile:**

```dockerfile
FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy project
COPY . .

# Collect static files
RUN python manage.py collectstatic --noinput

EXPOSE 8000

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "myproject.wsgi:application"]
```

**docker-compose.yml:**

```yaml
version: '3.8'

services:
  web:
    build: .
    command: python manage.py runserver 0.0.0.0:8000
    ports:
      - "8000:8000"
    environment:
      - DEBUG=1
      - DATABASE_URL=postgresql://user:pass@db:5432/django_db
    depends_on:
      - db
    volumes:
      - .:/app

  db:
    image: postgres:15
    environment:
      - POSTGRES_DB=django_db
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
    volumes:
      - postgres-data:/var/lib/postgresql/data

volumes:
  postgres-data:
```

### Express.js + Redis + PostgreSQL

**docker-compose.yml:**

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - DATABASE_URL=postgresql://user:pass@postgres:5432/mydb
      - REDIS_URL=redis://redis:6379
    depends_on:
      - postgres
      - redis

  postgres:
    image: postgres:15
    environment:
      - POSTGRES_DB=mydb
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=pass
    volumes:
      - postgres-data:/var/lib/postgresql/data

  redis:
    image: redis:alpine
    volumes:
      - redis-data:/data

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - app

volumes:
  postgres-data:
  redis-data:
```

---

## Docker Compose Reference

### Complete Example with All Common Options

```yaml
version: '3.8'

services:
  app:
    # Build configuration
    build:
      context: .              # Dockerfile location
      dockerfile: Dockerfile  # Custom Dockerfile name
      args:
        - BUILD_ENV=production
    
    # OR use pre-built image
    # image: myapp:latest
    
    # Container configuration
    container_name: my-app
    hostname: app-server
    
    # Port mapping
    ports:
      - "8080:8080"           # HOST:CONTAINER
      - "443:443"
    
    # Environment variables
    environment:
      - NODE_ENV=production
      - API_KEY=secret123
    
    # OR use env file
    env_file:
      - .env
    
    # Volume mounts
    volumes:
      - ./app:/app            # Bind mount (local:container)
      - app-data:/data        # Named volume
      - /var/log              # Anonymous volume
    
    # Networking
    networks:
      - frontend
      - backend
    
    # Dependencies
    depends_on:
      database:
        condition: service_healthy
    
    # Resource limits
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 512M
        reservations:
          cpus: '1'
          memory: 256M
    
    # Restart policy
    restart: unless-stopped  # Options: no, always, on-failure, unless-stopped
    
    # Health check
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    
    # Command override
    command: npm start
    
    # Working directory
    working_dir: /app
    
    # User
    user: "1000:1000"
    
    # Logging
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"

  database:
    image: postgres:15
    container_name: my-database
    environment:
      - POSTGRES_DB=mydb
      - POSTGRES_USER=user
      - POSTGRES_PASSWORD=password
    volumes:
      - db-data:/var/lib/postgresql/data
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql
    networks:
      - backend
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:alpine
    container_name: my-cache
    networks:
      - backend
    volumes:
      - redis-data:/data

# Named volumes
volumes:
  app-data:
  db-data:
  redis-data:

# Networks
networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true  # No external access
```

---

## Common Commands

### Basic Commands

```bash
# Build and start all services
docker-compose up

# Build and start in detached mode (background)
docker-compose up -d

# Build images before starting
docker-compose up --build

# Stop services (keeps containers)
docker-compose stop

# Start stopped services
docker-compose start

# Restart services
docker-compose restart

# Stop and remove containers, networks
docker-compose down

# Stop and remove everything including volumes
docker-compose down -v

# Stop and remove everything including images
docker-compose down --rmi all
```

### Management Commands

```bash
# List running containers
docker-compose ps

# List all containers (including stopped)
docker-compose ps -a

# View logs from all services
docker-compose logs

# Follow logs in real-time
docker-compose logs -f

# View logs from specific service
docker-compose logs -f app

# View last 100 lines of logs
docker-compose logs --tail=100

# Execute command in running container
docker-compose exec app bash

# Execute command in running container (no TTY)
docker-compose exec -T app ls -la

# Run one-off command in new container
docker-compose run app npm test

# Scale a service to multiple containers
docker-compose up -d --scale app=3

# View resource usage
docker-compose stats

# Validate compose file
docker-compose config

# List images
docker-compose images

# Pull latest images
docker-compose pull

# Build specific service
docker-compose build app

# Rebuild without cache
docker-compose build --no-cache
```

### Docker Commands (without compose)

```bash
# List running containers
docker ps

# List all containers
docker ps -a

# List images
docker images

# Remove container
docker rm <container-id>

# Remove image
docker rmi <image-id>

# View container logs
docker logs <container-id>

# Follow logs
docker logs -f <container-id>

# Execute command in container
docker exec -it <container-id> bash

# Inspect container
docker inspect <container-id>

# View container resource usage
docker stats

# Stop container
docker stop <container-id>

# Start container
docker start <container-id>

# Restart container
docker restart <container-id>
```

### Cleanup Commands

```bash
# Remove all stopped containers
docker container prune

# Remove all unused images
docker image prune

# Remove all unused volumes
docker volume prune

# Remove all unused networks
docker network prune

# Remove everything (dangerous!)
docker system prune

# Remove everything including volumes
docker system prune -a --volumes

# View disk usage
docker system df
```

---

## Best Practices

### 1. Use Multi-Stage Builds

Reduces final image size by separating build and runtime environments.

```dockerfile
# Build stage
FROM node:18 AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Production stage
FROM node:18-alpine
WORKDIR /app
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
CMD ["node", "dist/index.js"]
```

**Benefits:**
- Smaller final image (only runtime dependencies)
- Faster deployments
- More secure (no build tools in production)

### 2. Optimize Layer Caching

Order instructions from least to most frequently changing.

```dockerfile
# Good: Dependencies cached separately
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./        # Changes rarely
RUN npm install              # Cached if package.json unchanged
COPY . .                     # Changes often
RUN npm run build

# Bad: Everything rebuilds on any change
FROM node:18-alpine
WORKDIR /app
COPY . .                     # Copies everything first
RUN npm install              # Always runs
RUN npm run build
```

### 3. Use .dockerignore

Create `.dockerignore` to exclude unnecessary files:

```
# Dependencies
node_modules
npm-debug.log
yarn-error.log

# Build outputs
dist
build
*.log

# IDE
.vscode
.idea
*.swp

# Git
.git
.gitignore

# Environment files
.env
.env.local

# OS files
.DS_Store
Thumbs.db

# Documentation
README.md
docs/

# Tests
tests/
*.test.js
coverage/
```

### 4. Use Specific Image Versions

```dockerfile
# Bad: Version can change
FROM node:latest

# Good: Specific version
FROM node:18.17.0-alpine

# Better: Pin to exact digest
FROM node:18.17.0-alpine@sha256:abc123...
```

### 5. Run as Non-Root User

```dockerfile
FROM node:18-alpine

# Create app user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

WORKDIR /app

# Install dependencies as root
COPY package*.json ./
RUN npm ci --only=production

# Copy app files and set ownership
COPY --chown=nodejs:nodejs . .

# Switch to non-root user
USER nodejs

CMD ["node", "server.js"]
```

### 6. Use Environment Variables

**docker-compose.yml:**

```yaml
services:
  app:
    environment:
      # Direct values
      - NODE_ENV=production
      - PORT=3000
      
      # From .env file
      - DATABASE_URL=${DATABASE_URL}
      
      # With defaults
      - LOG_LEVEL=${LOG_LEVEL:-info}
    
    # OR use env_file
    env_file:
      - .env
      - .env.production
```

**.env file:**

```
DATABASE_URL=postgresql://user:pass@postgres:5432/mydb
REDIS_URL=redis://redis:6379
API_KEY=secret123
```

### 7. Implement Health Checks

**In Dockerfile:**

```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:8080/health || exit 1
```

**In docker-compose.yml:**

```yaml
services:
  app:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
```

### 8. Use Named Volumes for Data Persistence

```yaml
services:
  database:
    volumes:
      # Named volume (persisted)
      - db-data:/var/lib/postgresql/data
      
      # Bind mount (for development)
      - ./init.sql:/docker-entrypoint-initdb.d/init.sql

volumes:
  db-data:  # Survives docker-compose down
```

### 9. Leverage Build Arguments

```dockerfile
ARG NODE_VERSION=18
FROM node:${NODE_VERSION}-alpine

ARG BUILD_ENV=production
ENV NODE_ENV=${BUILD_ENV}

RUN echo "Building for ${BUILD_ENV}"
```

```bash
# Build with custom arguments
docker build --build-arg NODE_VERSION=20 --build-arg BUILD_ENV=staging .
```

### 10. Minimize Layers

```dockerfile
# Bad: Multiple layers
RUN apt-get update
RUN apt-get install -y curl
RUN apt-get install -y git
RUN apt-get clean

# Good: Single layer
RUN apt-get update && \
    apt-get install -y curl git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

### 11. Use .env Files for Configuration

**.env:**

```
# Database
DB_HOST=localhost
DB_PORT=5432
DB_NAME=myapp
DB_USER=user
DB_PASSWORD=secret

# Application
APP_PORT=3000
NODE_ENV=development
LOG_LEVEL=debug

# External services
REDIS_URL=redis://localhost:6379
API_KEY=your-api-key
```

**docker-compose.yml:**

```yaml
services:
  app:
    env_file:
      - .env
```

### 12. Separate Development and Production Configurations

**docker-compose.yml (base):**

```yaml
version: '3.8'

services:
  app:
    build: .
    environment:
      - NODE_ENV=production
```

**docker-compose.dev.yml:**

```yaml
version: '3.8'

services:
  app:
    environment:
      - NODE_ENV=development
    volumes:
      - ./src:/app/src  # Hot reload
    command: npm run dev
```

**Usage:**

```bash
# Development
docker-compose -f docker-compose.yml -f docker-compose.dev.yml up

# Production
docker-compose up
```

---

## Troubleshooting

### Common Issues and Solutions

#### Container Won't Start

```bash
# View logs
docker-compose logs app

# View detailed container info
docker inspect <container-name>

# Check if port is already in use
sudo lsof -i :8080

# Try starting in foreground to see errors
docker-compose up
```

#### Can't Connect to Database

```bash
# Check if database is healthy
docker-compose ps

# View database logs
docker-compose logs database

# Test connection from app container
docker-compose exec app ping database

# Check network connectivity
docker network ls
docker network inspect <network-name>
```

#### Volume Issues

```bash
# List volumes
docker volume ls

# Inspect volume
docker volume inspect <volume-name>

# Remove unused volumes
docker volume prune

# Remove specific volume
docker volume rm <volume-name>

# Fresh start (removes volumes)
docker-compose down -v
```

#### Build Failures

```bash
# Build with no cache
docker-compose build --no-cache

# View build progress
docker-compose build --progress=plain

# Build specific service
docker-compose build app

# Check Dockerfile syntax
docker build --check .
```

#### Permission Issues

```bash
# Run container as specific user
docker-compose exec --user root app bash

# Fix file permissions
docker-compose exec app chown -R node:node /app

# In Dockerfile, set correct permissions
COPY --chown=node:node . .
```

#### Network Issues

```bash
# List networks
docker network ls

# Inspect network
docker network inspect <network-name>

# Recreate network
docker-compose down
docker-compose up

# Test connectivity between containers
docker-compose exec app ping database
```

#### Memory/CPU Issues

```bash
# View resource usage
docker stats

# Set resource limits in docker-compose.yml
services:
  app:
    deploy:
      resources:
        limits:
          cpus: '2'
          memory: 512M
```

#### Image Size Too Large

```dockerfile
# Use multi-stage builds
FROM node:18 AS build
# ... build steps

FROM node:18-alpine
COPY --from=build /app/dist ./dist

# Use alpine images
FROM python:3.11-alpine

# Clean up in same layer
RUN apt-get update && \
    apt-get install -y package && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*
```

### Debugging Commands

```bash
# Enter running container
docker-compose exec app sh

# Run shell in new container
docker-compose run --rm app sh

# View container processes
docker-compose top

# View container changes
docker diff <container-id>

# Export container filesystem
docker export <container-id> > container.tar

# View image layers
docker history <image-name>

# Test Dockerfile locally
docker build --target build -t test .
docker run --rm -it test sh
```

### Common Error Messages

#### "port is already allocated"

```bash
# Find process using port
sudo lsof -i :8080

# Kill process
kill -9 <PID>

# Or change port in docker-compose.yml
ports:
  - "8081:8080"
```

#### "no space left on device"

```bash
# Clean up Docker
docker system prune -a --volumes

# Remove unused images
docker image prune -a

# Check disk usage
docker system df
```

#### "dial unix /var/run/docker.sock: connect: permission denied"

```bash
# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in, or:
newgrp docker
```

#### "network not found"

```bash
# Recreate networks
docker-compose down
docker-compose up
```

---

## Summary

### Quick Start Checklist

- [ ] Install Docker and Docker Compose
- [ ] Create `Dockerfile` in project root
- [ ] Create `docker-compose.yml` in project root
- [ ] Create `.dockerignore` file
- [ ] Configure environment variables
- [ ] Run `docker-compose up --build`
- [ ] Test application
- [ ] Check logs: `docker-compose logs -f`

### Essential Commands

```bash
# Start
docker-compose up -d

# Stop
docker-compose down

# Rebuild
docker-compose up --build

# View logs
docker-compose logs -f

# Clean up
docker system prune -a --volumes
```

### Key Principles

1. **One process per container** - Don't run multiple services in one container
2. **Use official base images** - More secure and maintained
3. **Keep images small** - Use alpine variants and multi-stage builds
4. **Don't store data in containers** - Use volumes
5. **Use environment variables** - For configuration
6. **Implement health checks** - For reliability
7. **Run as non-root user** - For security
8. **Version everything** - Don't use `latest` tags

---

## Additional Resources

- **Official Docker Documentation**: https://docs.docker.com
- **Docker Hub**: https://hub.docker.com (official images)
- **Compose Specification**: https://compose-spec.io
- **Dockerfile Best Practices**: https://docs.docker.com/develop/develop-images/dockerfile_best-practices
- **Docker Security**: https://docs.docker.com/engine/security

---

## License

This guide is provided as-is for educational purposes. Feel free to use and modify as needed.

---

**Last Updated**: January 2025

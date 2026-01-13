# Kubernetes Guide

A comprehensive, practical guide to deploying and managing applications with Kubernetes.

## Table of Contents

- [Overview](#overview)
- [Basic Concepts](#basic-concepts)
- [Getting Started](#getting-started)
- [Core Components](#core-components)
- [YAML Configuration Guide](#yaml-configuration-guide)
- [Common Application Examples](#common-application-examples)
- [Networking and Services](#networking-and-services)
- [Storage and Volumes](#storage-and-volumes)
- [ConfigMaps and Secrets](#configmaps-and-secrets)
- [Deployments and Rolling Updates](#deployments-and-rolling-updates)
- [Scaling and Autoscaling](#scaling-and-autoscaling)
- [Ingress and Load Balancing](#ingress-and-load-balancing)
- [Common Commands](#common-commands)
- [Best Practices](#best-practices)
- [Troubleshooting](#troubleshooting)

---

## Overview

Kubernetes (K8s) is an open-source container orchestration platform that automates deploying, scaling, and managing containerized applications across clusters of machines.

### Why Kubernetes?

- **Scalability**: Automatically scale applications up or down
- **High Availability**: Self-healing, automatic restarts, replication
- **Portability**: Run anywhere (cloud, on-premise, hybrid)
- **Declarative Configuration**: Define desired state, K8s maintains it
- **Service Discovery**: Built-in DNS and load balancing
- **Rolling Updates**: Zero-downtime deployments
- **Resource Management**: Efficient CPU and memory allocation

### Docker vs Kubernetes

| Docker/Docker Compose | Kubernetes |
|----------------------|------------|
| Single host | Multi-host cluster |
| Manual scaling | Auto-scaling |
| Basic networking | Advanced networking |
| Local development | Production orchestration |
| Simple setup | Complex but powerful |

---

## Basic Concepts

### Cluster Architecture

```
┌─────────────────────────────────────────────────┐
│                   CLUSTER                       │
│                                                 │
│  ┌──────────────┐     ┌──────────────────────┐ │
│  │ Control Plane│     │     Worker Nodes     │ │
│  │              │     │                      │ │
│  │ - API Server │────▶│  ┌────────────────┐ │ │
│  │ - Scheduler  │     │  │  Pod (App)     │ │ │
│  │ - Controller │     │  │  ┌──────────┐  │ │ │
│  │ - etcd       │     │  │  │Container │  │ │ │
│  └──────────────┘     │  │  └──────────┘  │ │ │
│                       │  └────────────────┘ │ │
│                       │                      │ │
│                       │  ┌────────────────┐ │ │
│                       │  │  Pod (DB)      │ │ │
│                       │  └────────────────┘ │ │
│                       └──────────────────────┘ │
└─────────────────────────────────────────────────┘
```

### Key Terms

| Term | Definition |
|------|------------|
| **Cluster** | Set of machines (nodes) running containerized applications |
| **Node** | A worker machine (physical or virtual) in the cluster |
| **Pod** | Smallest deployable unit; contains one or more containers |
| **Deployment** | Manages desired state for Pods (replicas, updates) |
| **Service** | Stable network endpoint to access Pods |
| **Namespace** | Virtual cluster for resource isolation |
| **ConfigMap** | Store non-sensitive configuration data |
| **Secret** | Store sensitive data (passwords, tokens) |
| **Volume** | Storage that persists beyond Pod lifecycle |
| **Ingress** | HTTP/HTTPS routing to services |
| **Label** | Key-value pairs for organizing resources |
| **Selector** | Query resources by labels |

---

## Getting Started

### Installation Options

#### 1. Minikube (Local Development)

```bash
# Install Minikube (Linux)
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Start cluster
minikube start

# Check status
minikube status

# Open dashboard
minikube dashboard
```

#### 2. Kind (Kubernetes in Docker)

```bash
# Install Kind
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Create cluster
kind create cluster --name dev-cluster

# Delete cluster
kind delete cluster --name dev-cluster
```

#### 3. Docker Desktop (Mac/Windows)

- Enable Kubernetes in Docker Desktop settings
- Automatically configures `kubectl`

#### 4. Cloud Providers

- **GKE** (Google Kubernetes Engine)
- **EKS** (Amazon Elastic Kubernetes Service)
- **AKS** (Azure Kubernetes Service)

### Install kubectl (Kubernetes CLI)

```bash
# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Verify installation
kubectl version --client

# Check cluster connection
kubectl cluster-info

# View nodes
kubectl get nodes
```

---

## Core Components

### 1. Pod

Smallest deployable unit in Kubernetes. Usually contains one container (but can have multiple).

**pod.yaml:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.25
    ports:
    - containerPort: 80
    resources:
      requests:
        memory: "64Mi"
        cpu: "250m"
      limits:
        memory: "128Mi"
        cpu: "500m"
```

```bash
# Create Pod
kubectl apply -f pod.yaml

# View Pods
kubectl get pods

# Describe Pod
kubectl describe pod nginx-pod

# View logs
kubectl logs nginx-pod

# Delete Pod
kubectl delete pod nginx-pod
```

### 2. Deployment

Manages Pods with replication, scaling, and updates.

**deployment.yaml:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
```

```bash
# Create Deployment
kubectl apply -f deployment.yaml

# View Deployments
kubectl get deployments

# View Pods created by Deployment
kubectl get pods -l app=nginx

# Scale Deployment
kubectl scale deployment nginx-deployment --replicas=5

# Update image
kubectl set image deployment/nginx-deployment nginx=nginx:1.26

# View rollout status
kubectl rollout status deployment/nginx-deployment

# Delete Deployment
kubectl delete deployment nginx-deployment
```

### 3. Service

Provides stable networking for Pods.

**service.yaml:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80        # Service port
    targetPort: 80  # Container port
  type: LoadBalancer  # Options: ClusterIP, NodePort, LoadBalancer
```

**Service Types:**

| Type | Description | Use Case |
|------|-------------|----------|
| **ClusterIP** | Internal cluster IP (default) | Internal communication |
| **NodePort** | Exposes on each Node's IP | Development, testing |
| **LoadBalancer** | Cloud provider load balancer | Production (cloud) |
| **ExternalName** | Maps to external DNS | External services |

```bash
# Create Service
kubectl apply -f service.yaml

# View Services
kubectl get services

# View Service details
kubectl describe service nginx-service

# Access service (if LoadBalancer)
kubectl get service nginx-service
# Use EXTERNAL-IP to access

# Port forward (for testing)
kubectl port-forward service/nginx-service 8080:80
# Access at localhost:8080
```

### 4. Namespace

Virtual clusters for resource isolation.

```bash
# List namespaces
kubectl get namespaces

# Create namespace
kubectl create namespace dev

# Create resource in namespace
kubectl apply -f deployment.yaml -n dev

# View resources in namespace
kubectl get all -n dev

# Set default namespace
kubectl config set-context --current --namespace=dev

# Delete namespace (deletes all resources in it)
kubectl delete namespace dev
```

**namespace.yaml:**

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    name: production
    environment: prod
```

---

## YAML Configuration Guide

### Basic Structure

Every Kubernetes YAML has four main sections:

```yaml
apiVersion: apps/v1      # API version
kind: Deployment         # Resource type
metadata:                # Resource metadata
  name: my-app
  labels:
    app: my-app
spec:                    # Resource specification
  # ... resource-specific configuration
```

### Complete Deployment Example

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: production
  labels:
    app: web-app
    version: v1
  annotations:
    description: "Production web application"
spec:
  replicas: 3
  
  # Label selector (must match template labels)
  selector:
    matchLabels:
      app: web-app
  
  # Rolling update strategy
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  
  # Pod template
  template:
    metadata:
      labels:
        app: web-app
        version: v1
    spec:
      # Container specifications
      containers:
      - name: web
        image: myapp:1.0.0
        imagePullPolicy: IfNotPresent
        
        ports:
        - containerPort: 8080
          name: http
          protocol: TCP
        
        # Environment variables
        env:
        - name: NODE_ENV
          value: production
        - name: DB_HOST
          valueFrom:
            configMapKeyRef:
              name: app-config
              key: database_host
        - name: DB_PASSWORD
          valueFrom:
            secretKeyRef:
              name: app-secrets
              key: db_password
        
        # Resource limits
        resources:
          requests:
            memory: "256Mi"
            cpu: "500m"
          limits:
            memory: "512Mi"
            cpu: "1000m"
        
        # Health checks
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
        
        # Volume mounts
        volumeMounts:
        - name: app-storage
          mountPath: /data
        - name: config
          mountPath: /config
          readOnly: true
      
      # Volumes
      volumes:
      - name: app-storage
        persistentVolumeClaim:
          claimName: app-pvc
      - name: config
        configMap:
          name: app-config
      
      # Security context
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 2000
      
      # Node selection
      nodeSelector:
        disktype: ssd
      
      # Tolerations
      tolerations:
      - key: "key1"
        operator: "Equal"
        value: "value1"
        effect: "NoSchedule"
```

---

## Common Application Examples

### Example 1: Simple Web Application

**app-deployment.yaml:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: nginx:1.25
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer
```

```bash
kubectl apply -f app-deployment.yaml
kubectl get all
```

### Example 2: Node.js Application with MongoDB

**namespace.yaml:**

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: nodejs-app
```

**mongodb-deployment.yaml:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mongodb
  namespace: nodejs-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mongodb
  template:
    metadata:
      labels:
        app: mongodb
    spec:
      containers:
      - name: mongodb
        image: mongo:6
        ports:
        - containerPort: 27017
        env:
        - name: MONGO_INITDB_ROOT_USERNAME
          value: admin
        - name: MONGO_INITDB_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mongo-secret
              key: password
        volumeMounts:
        - name: mongo-storage
          mountPath: /data/db
        resources:
          requests:
            memory: "256Mi"
            cpu: "500m"
          limits:
            memory: "512Mi"
            cpu: "1000m"
      volumes:
      - name: mongo-storage
        persistentVolumeClaim:
          claimName: mongo-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: mongodb-service
  namespace: nodejs-app
spec:
  selector:
    app: mongodb
  ports:
  - port: 27017
    targetPort: 27017
  type: ClusterIP
```

**app-deployment.yaml:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nodejs-app
  namespace: nodejs-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nodejs
  template:
    metadata:
      labels:
        app: nodejs
    spec:
      containers:
      - name: nodejs
        image: myapp:1.0.0
        ports:
        - containerPort: 3000
        env:
        - name: NODE_ENV
          value: production
        - name: MONGODB_URI
          value: mongodb://mongodb-service:27017/mydb
        - name: PORT
          value: "3000"
        livenessProbe:
          httpGet:
            path: /health
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /ready
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 5
        resources:
          requests:
            memory: "128Mi"
            cpu: "250m"
          limits:
            memory: "256Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: nodejs-service
  namespace: nodejs-app
spec:
  selector:
    app: nodejs
  ports:
  - port: 80
    targetPort: 3000
  type: LoadBalancer
```

**mongo-secret.yaml:**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: mongo-secret
  namespace: nodejs-app
type: Opaque
data:
  password: cGFzc3dvcmQxMjM=  # base64 encoded "password123"
```

**mongo-pvc.yaml:**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mongo-pvc
  namespace: nodejs-app
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

```bash
# Create namespace
kubectl apply -f namespace.yaml

# Create secret
kubectl apply -f mongo-secret.yaml

# Create PVC
kubectl apply -f mongo-pvc.yaml

# Deploy MongoDB
kubectl apply -f mongodb-deployment.yaml

# Deploy Node.js app
kubectl apply -f app-deployment.yaml

# Check everything
kubectl get all -n nodejs-app
```

### Example 3: Java Spring Boot with MySQL

**mysql-deployment.yaml:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: mysql-config
data:
  MYSQL_DATABASE: library
---
apiVersion: v1
kind: Secret
metadata:
  name: mysql-secret
type: Opaque
data:
  MYSQL_ROOT_PASSWORD: cm9vdHBhc3M=      # base64: rootpass
  MYSQL_USER: bGlicmFyeXVzZXI=           # base64: libraryuser
  MYSQL_PASSWORD: bGlicmFyeXBhc3M=       # base64: librarypass
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        ports:
        - containerPort: 3306
        env:
        - name: MYSQL_DATABASE
          valueFrom:
            configMapKeyRef:
              name: mysql-config
              key: MYSQL_DATABASE
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: MYSQL_ROOT_PASSWORD
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: MYSQL_USER
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: MYSQL_PASSWORD
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql
        livenessProbe:
          exec:
            command:
            - mysqladmin
            - ping
            - -h
            - localhost
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          exec:
            command:
            - mysql
            - -h
            - localhost
            - -u
            - root
            - -ppassword
            - -e
            - SELECT 1
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: mysql-storage
        persistentVolumeClaim:
          claimName: mysql-pvc
---
apiVersion: v1
kind: Service
metadata:
  name: mysql-service
spec:
  selector:
    app: mysql
  ports:
  - port: 3306
    targetPort: 3306
  type: ClusterIP
```

**spring-app-deployment.yaml:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: spring-app
spec:
  replicas: 3
  selector:
    matchLabels:
      app: spring
  template:
    metadata:
      labels:
        app: spring
    spec:
      containers:
      - name: spring
        image: myapp:1.0.0
        ports:
        - containerPort: 8080
        env:
        - name: SPRING_DATASOURCE_URL
          value: jdbc:mysql://mysql-service:3306/library
        - name: SPRING_DATASOURCE_USERNAME
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: MYSQL_USER
        - name: SPRING_DATASOURCE_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: MYSQL_PASSWORD
        livenessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 60
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /actuator/health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 5
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
---
apiVersion: v1
kind: Service
metadata:
  name: spring-service
spec:
  selector:
    app: spring
  ports:
  - port: 80
    targetPort: 8080
  type: LoadBalancer
```

```bash
kubectl apply -f mysql-deployment.yaml
kubectl apply -f spring-app-deployment.yaml
```

### Example 4: Python Flask with Redis

**redis-deployment.yaml:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: redis
spec:
  replicas: 1
  selector:
    matchLabels:
      app: redis
  template:
    metadata:
      labels:
        app: redis
    spec:
      containers:
      - name: redis
        image: redis:alpine
        ports:
        - containerPort: 6379
        resources:
          requests:
            memory: "64Mi"
            cpu: "250m"
          limits:
            memory: "128Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: redis-service
spec:
  selector:
    app: redis
  ports:
  - port: 6379
    targetPort: 6379
  type: ClusterIP
```

**flask-deployment.yaml:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: flask-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: flask
  template:
    metadata:
      labels:
        app: flask
    spec:
      containers:
      - name: flask
        image: myflaskapp:1.0.0
        ports:
        - containerPort: 5000
        env:
        - name: FLASK_ENV
          value: production
        - name: REDIS_HOST
          value: redis-service
        - name: REDIS_PORT
          value: "6379"
        resources:
          requests:
            memory: "128Mi"
            cpu: "250m"
          limits:
            memory: "256Mi"
            cpu: "500m"
---
apiVersion: v1
kind: Service
metadata:
  name: flask-service
spec:
  selector:
    app: flask
  ports:
  - port: 80
    targetPort: 5000
  type: LoadBalancer
```

---

## Networking and Services

### Service Types Deep Dive

#### ClusterIP (Default)

Internal cluster communication only.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  type: ClusterIP
  selector:
    app: backend
  ports:
  - port: 8080
    targetPort: 8080
```

```bash
# Access from within cluster
curl backend-service:8080
```

#### NodePort

Exposes service on each Node's IP at a static port (30000-32767).

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  type: NodePort
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080  # Optional, auto-assigned if not specified
```

```bash
# Access via any node IP
curl <node-ip>:30080
```

#### LoadBalancer

Cloud provider load balancer (AWS ELB, GCP Load Balancer, etc.).

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 8080
```

```bash
# Get external IP
kubectl get service web-service
# Access via EXTERNAL-IP
```

### Headless Service

For direct Pod communication (stateful applications).

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mysql-headless
spec:
  clusterIP: None  # Headless
  selector:
    app: mysql
  ports:
  - port: 3306
```

### DNS and Service Discovery

Services are automatically assigned DNS names:

```
<service-name>.<namespace>.svc.cluster.local
```

**Examples:**

```bash
# Within same namespace
curl http://backend-service:8080

# Cross-namespace
curl http://backend-service.production.svc.cluster.local:8080
```

---

## Storage and Volumes

### Volume Types

| Type | Description | Use Case |
|------|-------------|----------|
| **emptyDir** | Temporary, Pod lifecycle | Cache, scratch space |
| **hostPath** | Node's filesystem | Node-specific data (rare) |
| **persistentVolumeClaim** | Persistent storage | Databases, user data |
| **configMap** | Configuration files | App config |
| **secret** | Sensitive data | Passwords, keys |
| **nfs** | Network File System | Shared storage |

### emptyDir (Temporary Storage)

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: cache
      mountPath: /cache
  volumes:
  - name: cache
    emptyDir: {}
```

### PersistentVolume and PersistentVolumeClaim

**persistent-volume.yaml:**

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: app-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  storageClassName: standard
  hostPath:
    path: /mnt/data
```

**persistent-volume-claim.yaml:**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: app-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: standard
```

**Using PVC in Deployment:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app
  template:
    metadata:
      labels:
        app: app
    spec:
      containers:
      - name: app
        image: myapp:1.0.0
        volumeMounts:
        - name: storage
          mountPath: /data
      volumes:
      - name: storage
        persistentVolumeClaim:
          claimName: app-pvc
```

### StorageClass (Dynamic Provisioning)

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-storage
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp3
  iopsPerGB: "10"
  fsType: ext4
```

**PVC with StorageClass:**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: fast-pvc
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: fast-storage
  resources:
    requests:
      storage: 20Gi
```

---

## ConfigMaps and Secrets

### ConfigMap

Store non-sensitive configuration.

**configmap.yaml:**

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  database_host: mysql-service
  database_port: "3306"
  log_level: "info"
  app.properties: |
    server.port=8080
    server.context-path=/api
```

```bash
# Create from file
kubectl create configmap app-config --from-file=config.properties

# Create from literal
kubectl create configmap app-config --from-literal=key1=value1
```

**Using ConfigMap:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  containers:
  - name: app
    image: myapp:1.0.0
    env:
    # Single value
    - name: DB_HOST
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: database_host
    
    # All values as env vars
    envFrom:
    - configMapRef:
        name: app-config
    
    # Mount as volume
    volumeMounts:
    - name: config
      mountPath: /config
  volumes:
  - name: config
    configMap:
      name: app-config
```

### Secret

Store sensitive data (base64 encoded).

**secret.yaml:**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: app-secret
type: Opaque
data:
  username: YWRtaW4=           # base64: admin
  password: cGFzc3dvcmQxMjM=   # base64: password123
```

```bash
# Create secret from literal
kubectl create secret generic app-secret \
  --from-literal=username=admin \
  --from-literal=password=password123

# Create secret from file
kubectl create secret generic app-secret \
  --from-file=ssh-privatekey=~/.ssh/id_rsa

# Encode/decode base64
echo -n "password123" | base64
echo "cGFzc3dvcmQxMjM=" | base64 --decode
```

**Using Secret:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app
spec:
  containers:
  - name: app
    image: myapp:1.0.0
    env:
    - name: DB_USERNAME
      valueFrom:
        secretKeyRef:
          name: app-secret
          key: username
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: app-secret
          key: password
    
    # Mount as volume
    volumeMounts:
    - name: secret
      mountPath: /secrets
      readOnly: true
  volumes:
  - name: secret
    secret:
      secretName: app-secret
```

**Docker Registry Secret:**

```bash
kubectl create secret docker-registry regcred \
  --docker-server=docker.io \
  --docker-username=myuser \
  --docker-password=mypass \
  --docker-email=email@example.com
```

```yaml
spec:
  imagePullSecrets:
  - name: regcred
  containers:
  - name: app
    image: myuser/private-image:1.0.0
```

---

## Deployments and Rolling Updates

### Deployment Strategies

#### Rolling Update (Default)

Gradually replace old Pods with new ones.

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
spec:
  replicas: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2        # Max new Pods during update
      maxUnavailable: 1  # Max unavailable Pods
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: app
        image: myapp:1.0.0
```

#### Recreate

Delete all old Pods, then create new ones (downtime).

```yaml
spec:
  strategy:
    type: Recreate
```

### Update Commands

```bash
# Update image
kubectl set image deployment/app app=myapp:2.0.0

# Edit deployment
kubectl edit deployment app

# Apply updated YAML
kubectl apply -f deployment.yaml

# View rollout status
kubectl rollout status deployment/app

# View rollout history
kubectl rollout history deployment/app

# Rollback to previous version
kubectl rollout undo deployment/app

# Rollback to specific revision
kubectl rollout undo deployment/app --to-revision=2

# Pause rollout
kubectl rollout pause deployment/app

# Resume rollout
kubectl rollout resume deployment/app
```

### Blue-Green Deployment

**blue-deployment.yaml:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: blue
  template:
    metadata:
      labels:
        app: myapp
        version: blue
    spec:
      containers:
      - name: app
        image: myapp:1.0.0
```

**green-deployment.yaml:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
      version: green
  template:
    metadata:
      labels:
        app: myapp
        version: green
    spec:
      containers:
      - name: app
        image: myapp:2.0.0
```

**service.yaml:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: app-service
spec:
  selector:
    app: myapp
    version: blue  # Switch to 'green' for cutover
  ports:
  - port: 80
    targetPort: 8080
```

```bash
# Deploy green
kubectl apply -f green-deployment.yaml

# Switch traffic to green
kubectl patch service app-service -p '{"spec":{"selector":{"version":"green"}}}'

# Remove blue after verification
kubectl delete deployment app-blue
```

### Canary Deployment

```yaml
# Main deployment (90% traffic)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-stable
spec:
  replicas: 9
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
        version: stable
    spec:
      containers:
      - name: app
        image: myapp:1.0.0
---
# Canary deployment (10% traffic)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-canary
spec:
  replicas: 1
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
        version: canary
    spec:
      containers:
      - name: app
        image: myapp:2.0.0
---
apiVersion: v1
kind: Service
metadata:
  name: app-service
spec:
  selector:
    app: myapp  # Selects both stable and canary
  ports:
  - port: 80
    targetPort: 8080
```

---

## Scaling and Autoscaling

### Manual Scaling

```bash
# Scale deployment
kubectl scale deployment app --replicas=5

# Scale in YAML
kubectl apply -f deployment.yaml  # with replicas: 5
```

### Horizontal Pod Autoscaler (HPA)

Automatically scales based on CPU/memory usage.

**hpa.yaml:**

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
```

```bash
# Create HPA
kubectl apply -f hpa.yaml

# Or via command
kubectl autoscale deployment app --cpu-percent=70 --min=2 --max=10

# View HPA
kubectl get hpa

# Describe HPA
kubectl describe hpa app-hpa

# Delete HPA
kubectl delete hpa app-hpa
```

**Requirements for HPA:**

```yaml
# Deployment must have resource requests
spec:
  containers:
  - name: app
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
```

```bash
# Install metrics server (if not installed)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### Vertical Pod Autoscaler (VPA)

Adjusts CPU/memory requests automatically.

```yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: app-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: app
  updatePolicy:
    updateMode: "Auto"  # Options: Off, Initial, Recreate, Auto
```

---

## Ingress and Load Balancing

### Ingress Controller

Install NGINX Ingress Controller:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.9.4/deploy/static/provider/cloud/deploy.yaml
```

### Basic Ingress

**ingress.yaml:**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: app-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-service
            port:
              number: 80
```

```bash
kubectl apply -f ingress.yaml
kubectl get ingress
```

### Multiple Hosts

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-host-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: app1.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app1-service
            port:
              number: 80
  - host: app2.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app2-service
            port:
              number: 80
```

### Path-Based Routing

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: path-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: backend-service
            port:
              number: 8080
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
```

### TLS/HTTPS

**Create TLS secret:**

```bash
kubectl create secret tls tls-secret \
  --cert=path/to/tls.crt \
  --key=path/to/tls.key
```

**ingress-tls.yaml:**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-ingress
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - myapp.example.com
    secretName: tls-secret
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-service
            port:
              number: 80
```

---

## Common Commands

### Cluster and Context

```bash
# View cluster info
kubectl cluster-info

# View nodes
kubectl get nodes

# Describe node
kubectl describe node <node-name>

# View contexts
kubectl config get-contexts

# Switch context
kubectl config use-context <context-name>

# Set namespace
kubectl config set-context --current --namespace=dev
```

### Resources

```bash
# Get all resources
kubectl get all

# Get specific resource type
kubectl get pods
kubectl get deployments
kubectl get services
kubectl get ingress

# Get with labels
kubectl get pods -l app=nginx

# Get from all namespaces
kubectl get pods --all-namespaces
kubectl get pods -A

# Wide output (more details)
kubectl get pods -o wide

# YAML output
kubectl get pod nginx-pod -o yaml

# JSON output
kubectl get pod nginx-pod -o json

# Watch for changes
kubectl get pods --watch
```

### Create and Apply

```bash
# Create from file
kubectl create -f deployment.yaml

# Apply (create or update)
kubectl apply -f deployment.yaml

# Apply directory
kubectl apply -f ./configs/

# Delete resource
kubectl delete -f deployment.yaml
kubectl delete pod nginx-pod
kubectl delete deployment app

# Delete all in namespace
kubectl delete all --all -n dev
```

### Describe and Logs

```bash
# Describe resource
kubectl describe pod nginx-pod
kubectl describe deployment app
kubectl describe service app-service

# View logs
kubectl logs nginx-pod

# Follow logs
kubectl logs -f nginx-pod

# Previous container logs
kubectl logs nginx-pod --previous

# Logs from specific container
kubectl logs nginx-pod -c container-name

# Logs from all containers
kubectl logs nginx-pod --all-containers

# Tail last 100 lines
kubectl logs nginx-pod --tail=100
```

### Execute and Debug

```bash
# Execute command in pod
kubectl exec nginx-pod -- ls /app

# Interactive shell
kubectl exec -it nginx-pod -- /bin/bash
kubectl exec -it nginx-pod -- sh

# Port forward
kubectl port-forward pod/nginx-pod 8080:80
kubectl port-forward service/nginx-service 8080:80
kubectl port-forward deployment/nginx 8080:80

# Copy files
kubectl cp nginx-pod:/path/to/file ./local-file
kubectl cp ./local-file nginx-pod:/path/to/file

# Top (resource usage)
kubectl top nodes
kubectl top pods
kubectl top pods --containers
```

### Labels and Annotations

```bash
# Add label
kubectl label pod nginx-pod env=production

# Remove label
kubectl label pod nginx-pod env-

# Update label
kubectl label pod nginx-pod env=staging --overwrite

# Get by label
kubectl get pods -l env=production

# Add annotation
kubectl annotate pod nginx-pod description="web server"

# Show labels
kubectl get pods --show-labels
```

### Edit Resources

```bash
# Edit resource
kubectl edit deployment app

# Set image
kubectl set image deployment/app app=myapp:2.0.0

# Set resources
kubectl set resources deployment app -c=app --limits=cpu=200m,memory=512Mi

# Set env
kubectl set env deployment/app KEY=value
```

### Rollout Management

```bash
# Rollout status
kubectl rollout status deployment/app

# Rollout history
kubectl rollout history deployment/app

# Undo rollout
kubectl rollout undo deployment/app

# Undo to specific revision
kubectl rollout undo deployment/app --to-revision=2

# Pause rollout
kubectl rollout pause deployment/app

# Resume rollout
kubectl rollout resume deployment/app

# Restart deployment
kubectl rollout restart deployment/app
```

### Scaling

```bash
# Scale deployment
kubectl scale deployment app --replicas=5

# Autoscale
kubectl autoscale deployment app --min=2 --max=10 --cpu-percent=80
```

### Advanced

```bash
# Drain node (for maintenance)
kubectl drain <node-name> --ignore-daemonsets

# Uncordon node
kubectl uncordon <node-name>

# Cordon node (mark unschedulable)
kubectl cordon <node-name>

# Taint node
kubectl taint nodes node1 key=value:NoSchedule

# Remove taint
kubectl taint nodes node1 key=value:NoSchedule-

# Apply resource quota
kubectl create quota my-quota --hard=cpu=1,memory=1G,pods=2

# View API resources
kubectl api-resources

# View API versions
kubectl api-versions

# Explain resource
kubectl explain pod
kubectl explain pod.spec.containers

# Diff before apply
kubectl diff -f deployment.yaml

# Dry run
kubectl apply -f deployment.yaml --dry-run=client
kubectl apply -f deployment.yaml --dry-run=server
```

---

## Best Practices

### 1. Use Namespaces for Isolation

```yaml
# Separate environments
kubectl create namespace dev
kubectl create namespace staging
kubectl create namespace production

# Apply resource quotas per namespace
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: dev
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 40Gi
    pods: "50"
```

### 2. Set Resource Requests and Limits

```yaml
spec:
  containers:
  - name: app
    resources:
      requests:        # Guaranteed resources
        memory: "256Mi"
        cpu: "500m"
      limits:          # Maximum resources
        memory: "512Mi"
        cpu: "1000m"
```

### 3. Use Liveness and Readiness Probes

```yaml
spec:
  containers:
  - name: app
    livenessProbe:
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 30
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3
    
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 10
      periodSeconds: 5
      timeoutSeconds: 3
      failureThreshold: 3
```

**Probe Types:**

```yaml
# HTTP probe
livenessProbe:
  httpGet:
    path: /health
    port: 8080

# TCP probe
livenessProbe:
  tcpSocket:
    port: 8080

# Command probe
livenessProbe:
  exec:
    command:
    - cat
    - /tmp/healthy
```

### 4. Use ConfigMaps and Secrets

```yaml
# Don't hardcode configuration
# Bad:
env:
- name: DB_HOST
  value: "mysql.example.com"

# Good:
env:
- name: DB_HOST
  valueFrom:
    configMapKeyRef:
      name: app-config
      key: database_host
```

### 5. Implement Pod Security

```yaml
# Security context
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
    fsGroup: 2000
  containers:
  - name: app
    securityContext:
      allowPrivilegeEscalation: false
      readOnlyRootFilesystem: true
      capabilities:
        drop:
        - ALL
```

### 6. Use Labels Effectively

```yaml
metadata:
  labels:
    app: myapp
    version: v1.2.3
    environment: production
    tier: backend
    owner: team-alpha
```

```bash
# Query by labels
kubectl get pods -l app=myapp,environment=production
```

### 7. Implement Network Policies

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
```

### 8. Use Rolling Updates

```yaml
spec:
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0  # Zero downtime
```

### 9. Implement Resource Quotas

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: quota
  namespace: dev
spec:
  hard:
    requests.cpu: "10"
    requests.memory: 20Gi
    limits.cpu: "20"
    limits.memory: 40Gi
    persistentvolumeclaims: "10"
    pods: "50"
    services.loadbalancers: "2"
```

### 10. Use Pod Disruption Budgets

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: app-pdb
spec:
  minAvailable: 2  # Or maxUnavailable: 1
  selector:
    matchLabels:
      app: myapp
```

### 11. Version Your Images

```yaml
# Bad: Uses latest tag
image: myapp:latest

# Good: Specific version
image: myapp:1.2.3

# Best: Immutable digest
image: myapp@sha256:abc123...
```

### 12. Use Init Containers

```yaml
spec:
  initContainers:
  - name: wait-for-db
    image: busybox:1.36
    command: ['sh', '-c', 'until nc -z mysql-service 3306; do sleep 1; done']
  containers:
  - name: app
    image: myapp:1.0.0
```

---

## Troubleshooting

### Pod Issues

#### Pod Stuck in Pending

```bash
# Check events
kubectl describe pod <pod-name>

# Common causes:
# - Insufficient resources
# - No nodes match selector
# - PVC not bound
# - Image pull errors
```

#### Pod CrashLoopBackOff

```bash
# View logs
kubectl logs <pod-name>
kubectl logs <pod-name> --previous

# Common causes:
# - Application crashes
# - Missing dependencies
# - Configuration errors
# - Failed health checks
```

#### ImagePullBackOff

```bash
kubectl describe pod <pod-name>

# Common causes:
# - Wrong image name/tag
# - Private registry without credentials
# - Network issues
# - Image doesn't exist

# Solution: Create image pull secret
kubectl create secret docker-registry regcred \
  --docker-server=docker.io \
  --docker-username=user \
  --docker-password=pass
```

#### Pod Evicted

```bash
# Check node pressure
kubectl describe node <node-name>

# Common causes:
# - Node out of disk space
# - Node out of memory
# - Node has pressure

# Solution: Clean up or add resources
```

### Service Issues

#### Service Not Accessible

```bash
# Check service
kubectl get service <service-name>
kubectl describe service <service-name>

# Check endpoints
kubectl get endpoints <service-name>

# Test from within cluster
kubectl run -it --rm debug --image=busybox:1.36 --restart=Never -- sh
wget -O- http://service-name:80

# Verify selector matches pod labels
kubectl get pods --show-labels
```

### Networking Issues

```bash
# Check DNS
kubectl run -it --rm debug --image=busybox:1.36 --restart=Never -- sh
nslookup kubernetes.default
nslookup service-name.namespace.svc.cluster.local

# Check network policies
kubectl get networkpolicies

# Describe network policy
kubectl describe networkpolicy <policy-name>
```

### Storage Issues

```bash
# Check PVC status
kubectl get pvc

# Describe PVC
kubectl describe pvc <pvc-name>

# Check PV
kubectl get pv

# Common issues:
# - No PV available
# - Access mode mismatch
# - Storage class not found
```

### Resource Issues

```bash
# Check resource usage
kubectl top nodes
kubectl top pods

# Check resource quotas
kubectl get resourcequota
kubectl describe resourcequota <quota-name>

# Check limit ranges
kubectl get limitrange
kubectl describe limitrange <limitrange-name>
```

### Debugging Commands

```bash
# Run debug pod
kubectl run debug --image=busybox:1.36 -it --rm --restart=Never -- sh

# Debug with curl
kubectl run curl --image=curlimages/curl -it --rm --restart=Never -- sh

# Debug with network tools
kubectl run netshoot --image=nicolaka/netshoot -it --rm --restart=Never -- bash

# Copy pod for debugging
kubectl debug <pod-name> -it --copy-to=debug-pod --image=busybox:1.36

# View events
kubectl get events --sort-by='.lastTimestamp'
kubectl get events -A

# Check cluster components
kubectl get componentstatuses
kubectl get pods -n kube-system
```

### Common Error Messages

#### "Insufficient CPU/Memory"

```bash
# Check node resources
kubectl top nodes

# Check pod requests
kubectl describe pod <pod-name>

# Solution:
# 1. Reduce resource requests
# 2. Add more nodes
# 3. Delete unused pods
```

#### "No route to host"

```bash
# Check service
kubectl get svc

# Check endpoints
kubectl get ep

# Verify network connectivity
kubectl exec -it <pod> -- ping <service-ip>
```

#### "Connection refused"

```bash
# Verify pod is running
kubectl get pods

# Check port
kubectl describe pod <pod-name>

# Test locally
kubectl port-forward pod/<pod-name> 8080:80
curl localhost:8080
```

---

## Summary

### Quick Start Workflow

1. **Create namespace**: `kubectl create namespace myapp`
2. **Create ConfigMap/Secret**: `kubectl apply -f config.yaml`
3. **Create Storage**: `kubectl apply -f pvc.yaml`
4. **Deploy application**: `kubectl apply -f deployment.yaml`
5. **Expose service**: `kubectl apply -f service.yaml`
6. **Configure ingress**: `kubectl apply -f ingress.yaml`
7. **Monitor**: `kubectl get all -n myapp`

### Essential Commands Quick Reference

```bash
# Deploy
kubectl apply -f app.yaml

# View resources
kubectl get all
kubectl get pods -o wide

# View logs
kubectl logs -f pod-name

# Debug
kubectl describe pod pod-name
kubectl exec -it pod-name -- sh

# Scale
kubectl scale deployment app --replicas=5

# Update
kubectl set image deployment/app app=myapp:2.0.0

# Rollback
kubectl rollout undo deployment/app

# Delete
kubectl delete -f app.yaml
```

### Key Principles

1. **Declarative Configuration** - Define desired state in YAML
2. **Self-Healing** - Automatically restarts failed containers
3. **Horizontal Scaling** - Add more Pods, not bigger Pods
4. **Service Discovery** - Use DNS names, not IPs
5. **Rolling Updates** - Zero-downtime deployments
6. **Resource Management** - Set requests and limits
7. **Health Checks** - Implement liveness and readiness probes
8. **Security** - Use RBAC, network policies, security contexts
9. **Observability** - Centralized logging and monitoring
10. **GitOps** - Store configs in version control

### Resource Hierarchy

```
Cluster
  ├── Namespace
  │     ├── Deployment
  │     │     └── ReplicaSet
  │     │           └── Pod
  │     │                 └── Container
  │     ├── Service
  │     ├── ConfigMap
  │     ├── Secret
  │     └── PersistentVolumeClaim
  └── Node
```

---

## Additional Resources

- **Official Kubernetes Documentation**: https://kubernetes.io/docs
- **Kubernetes API Reference**: https://kubernetes.io/docs/reference
- **kubectl Cheat Sheet**: https://kubernetes.io/docs/reference/kubectl/cheatsheet
- **Kubernetes The Hard Way**: https://github.com/kelseyhightower/kubernetes-the-hard-way
- **Helm (Package Manager)**: https://helm.sh
- **Kustomize (Config Management)**: https://kustomize.io
- **K9s (Terminal UI)**: https://k9scli.io

---

## License

This guide is provided as-is for educational purposes. Feel free to use and modify as needed.

---

**Last Updated**: January 2026
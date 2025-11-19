# Architecture Comparison: Local vs GCP

## Local Development (Docker Compose)

```
┌──────────────────────────────────────────────────────┐
│                  Your Computer                       │
│                                                      │
│  ┌────────────────────────────────────────────────┐ │
│  │         Docker Compose Network                 │ │
│  │           (book_network)                       │ │
│  │                                                │ │
│  │   ┌──────────────┐      ┌──────────────┐     │ │
│  │   │   book_app   │      │   book_db    │     │ │
│  │   │  (Flask)     │─────▶│   (MySQL)    │     │ │
│  │   │  Port: 5000  │      │   Port: 3306 │     │ │
│  │   └──────────────┘      └──────────────┘     │ │
│  │         │                                     │ │
│  │         │ Container can use                   │ │
│  │         │ hostname "db"                       │ │
│  │         │                                     │ │
│  └─────────┼─────────────────────────────────────┘ │
│            │                                        │
│            ▼                                        │
│      localhost:5000                                 │
└──────────────────────────────────────────────────────┘

Connection String: MYSQL_HOST=db (uses Docker DNS)
```

---

## GCP Production (Multi-VM)

```
┌────────────────────────────────────────────────────────────────────┐
│                      Google Cloud Platform                         │
│                      VPC Network (10.128.0.0/24)                   │
│                                                                    │
│  ┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐ │
│  │   Jenkins VM    │   │   App VM        │   │  Database VM    │ │
│  │  10.128.0.2     │   │  10.128.0.3     │   │  10.128.0.4     │ │
│  │                 │   │                 │   │                 │ │
│  │  ┌───────────┐  │   │  ┌───────────┐  │   │  ┌───────────┐ │ │
│  │  │  Jenkins  │  │   │  │ book_app  │  │   │  │  book_db  │ │ │
│  │  │ Container │  │   │  │ Container │──┼───┼─▶│ Container │ │ │
│  │  │           │  │   │  │           │  │   │  │           │ │ │
│  │  │ Port 8080 │  │   │  │ Port 5000 │  │   │  │ Port 3306 │ │ │
│  │  └───────────┘  │   │  └───────────┘  │   │  └───────────┘ │ │
│  │  ┌───────────┐  │   │       │         │   │                │ │
│  │  │ SonarQube │  │   │  ┌────▼──────┐  │   │                │ │
│  │  │ Container │  │   │  │   Nginx   │  │   │                │ │
│  │  │ Port 9000 │  │   │  │  Port 80  │  │   │                │ │
│  │  └───────────┘  │   │  └───────────┘  │   │                │ │
│  └─────────┬───────┘   └────────┬────────┘   └────────────────┘ │
│            │                    │                                │
│            ▼                    ▼                                │
│        Port 8080            Port 80/443                          │
└────────────┼────────────────────┼──────────────────────────────────┘
             │                    │
             ▼                    ▼
         Internet            Internet
    (Jenkins Dashboard)   (Your Application)

Connection String: MYSQL_HOST=10.128.0.4 (uses VM internal IP)
```

---

## Key Architectural Differences

### 1. Networking

| Aspect | Local | GCP |
|--------|-------|-----|
| **Network Type** | Docker bridge network | GCP VPC network |
| **DNS Resolution** | Docker DNS (container names) | No DNS, must use IPs |
| **IP Addresses** | Dynamic internal (172.x.x.x) | Static internal (10.128.0.x) |
| **Network Isolation** | Single host, isolated network | Multi-host, shared VPC |

### 2. Container Communication

**Local:**
```python
# frontend/config.py
MYSQL_HOST = os.getenv('MYSQL_HOST', 'localhost')

# docker-compose.yml sets:
MYSQL_HOST=db  # ✓ Works because Docker DNS resolves "db" to container IP
```

**GCP:**
```python
# frontend/config.py (same code!)
MYSQL_HOST = os.getenv('MYSQL_HOST', 'localhost')

# But you run container with:
MYSQL_HOST=10.128.0.4  # ✓ Must use actual internal IP of Database VM
```

### 3. Port Exposure

**Local:**
```yaml
# docker-compose.yml
services:
  db:
    ports:
      - "3306:3306"  # ← Optional, only needed if you want to connect from host
```

**GCP:**
```bash
# Docker run command on Database VM
docker run -p 3306:3306 ...  # ← REQUIRED! App VM needs to connect from outside
```

### 4. Data Flow Comparison

**Local Development:**
```
Browser → localhost:5000 → book_app container → book_db container
                           (via Docker network)
```

**GCP Production:**
```
Browser → External IP:80 → Nginx → book_app container (10.128.0.3)
                                    ↓
                          GCP Internal Network
                                    ↓
                         book_db container (10.128.0.4:3306)
```

---

## Environment Variables Comparison

### Local (docker-compose.yml)
```yaml
frontend:
  environment:
    - MYSQL_HOST=db           # ← Uses container name
    - MYSQL_USER=root
    - MYSQL_PASSWORD=Nitish@1234
    - MYSQL_DATABASE=book_db
```

### GCP (docker run on App VM)
```bash
docker run -d \
  -e MYSQL_HOST=10.128.0.4    # ← Uses internal IP
  -e MYSQL_USER=root \
  -e MYSQL_PASSWORD=Nitish@1234 \
  -e MYSQL_DATABASE=book_db \
  book-manager-app
```

---

## Firewall Rules

### Local
```
None needed - Docker handles everything internally
```

### GCP
```bash
# Allow App VM to connect to Database VM
gcloud compute firewall-rules create allow-mysql-internal \
  --allow tcp:3306 \
  --source-tags app-vm \
  --target-tags db-vm

# Allow internet to access App VM
gcloud compute firewall-rules create allow-http-https \
  --allow tcp:80,tcp:443 \
  --source-ranges 0.0.0.0/0

# Allow internet to access Jenkins
gcloud compute firewall-rules create allow-jenkins \
  --allow tcp:8080,tcp:9000 \
  --source-ranges 0.0.0.0/0
```

---

## Testing Connectivity

### Local
```bash
# Test from host machine
docker-compose ps
curl http://localhost:5000

# Test from inside container
docker exec book_app ping db
docker exec book_app nc -zv db 3306
```

### GCP
```bash
# Test from App VM to Database VM
gcloud compute ssh app-vm --zone=us-central1-a

# Install tools
sudo apt-get install -y mysql-client netcat

# Test connectivity
ping 10.128.0.4
nc -zv 10.128.0.4 3306
mysql -h 10.128.0.4 -uroot -pNitish@1234 -e "SHOW DATABASES;"

# Test from inside container
docker exec book_app sh -c "nc -zv 10.128.0.4 3306"
```

---

## Deployment Workflow

### Local
```bash
# Single command starts everything
docker-compose up -d

# Both containers on same machine
# Connected automatically via Docker network
```

### GCP
```bash
# Step 1: Setup Database VM
gcloud compute ssh database-vm
./database-vm-setup.sh
docker ps  # Verify MySQL running

# Step 2: Get Database VM's internal IP
hostname -I | awk '{print $1}'  # e.g., 10.128.0.4

# Step 3: Setup App VM with Database IP
gcloud compute ssh app-vm
./app-vm-setup.sh
docker run -e MYSQL_HOST=10.128.0.4 ...  # Use IP from Step 2

# Step 4: Setup Jenkins VM
gcloud compute ssh jenkins-vm
./jenkins-vm-setup.sh
```

---

## Cost Comparison

| Environment | Monthly Cost |
|-------------|--------------|
| **Local** | $0 (uses your computer) |
| **GCP** | ~$71/month (3 VMs running 24/7) |

---

## Summary

| Feature | Local (Docker Compose) | GCP (Multi-VM) |
|---------|----------------------|----------------|
| **Setup Complexity** | Easy (1 command) | Complex (3 VMs, firewall rules) |
| **Container Communication** | Automatic (Docker DNS) | Manual (IP configuration) |
| **Scalability** | Limited to 1 machine | Unlimited (horizontal scaling) |
| **Cost** | Free | ~$71/month |
| **Internet Access** | Manual port forwarding | Automatic (external IPs) |
| **Data Persistence** | Local volumes | VM disks + volumes |
| **High Availability** | No | Yes (can add load balancers) |
| **Best For** | Development & Testing | Production deployment |

**Key Takeaway:**
- **Local**: Containers talk via Docker network using container names
- **GCP**: Containers talk via GCP VPC using internal IP addresses
- **Same Application Code**: Works in both environments with environment variables!

# GCP Deployment Guide - Multi-VM Architecture

## Architecture Overview

```
┌─────────────────┐      ┌─────────────────┐      ┌─────────────────┐
│   Jenkins VM    │      │  Application VM │      │   Database VM   │
│  (10.128.0.2)   │─────▶│  (10.128.0.3)   │─────▶│  (10.128.0.4)   │
│                 │      │                 │      │                 │
│ - Jenkins       │      │ - Docker        │      │ - Docker        │
│ - SonarQube     │      │ - Nginx         │      │ - MySQL 8.0     │
│ - Docker        │      │ - Flask App     │      │                 │
└─────────────────┘      └─────────────────┘      └─────────────────┘
        │                        │
        │                        │
        └────────────────────────┘
              Internet Access
```

## Key Differences from Local Development

| Component | Local (Docker Compose) | GCP (Multi-VM) |
|-----------|----------------------|----------------|
| **Networking** | Single host, Docker bridge network | Multiple VMs, GCP VPC network |
| **DB Connection** | `MYSQL_HOST=db` (container name) | `MYSQL_HOST=10.128.0.4` (internal IP) |
| **Port Exposure** | Internal only | Must expose with `-p` flag |
| **Firewall** | None needed | GCP firewall rules required |
| **Data Persistence** | Docker volumes | VM disk + Docker volumes |

## Step 1: Create GCP VMs

```bash
# Set your project
gcloud config set project cosmic-slate-469618-h1

# Configure git remote (if not already done)
git remote add origin github-personal:HarshilForWork/Devops_MINI.git
git remote -v

# Create VPCs and firewall rules
gcloud compute firewall-rules create allow-jenkins \
  --allow tcp:8080,tcp:9000,tcp:22 \
  --source-ranges 0.0.0.0/0 \
  --description "Allow Jenkins and SonarQube"

gcloud compute firewall-rules create allow-http-https \
  --allow tcp:80,tcp:443,tcp:22 \
  --source-ranges 0.0.0.0/0 \
  --description "Allow HTTP/HTTPS"

gcloud compute firewall-rules create allow-mysql-internal \
  --allow tcp:3306 \
  --source-tags app-vm \
  --target-tags db-vm \
  --description "Allow MySQL from App VM only"

# Create Jenkins VM
gcloud compute instances create jenkins-vm \
  --zone=asia-south1-a \
  --machine-type=e2-medium \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=30GB \
  --tags=jenkins-vm

# Create Application VM
gcloud compute instances create app-vm \
  --zone=asia-south1-a \
  --machine-type=e2-micro \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=10GB \
  --tags=app-vm

# Create Database VM
gcloud compute instances create database-vm \
  --zone=asia-south1-a \
  --machine-type=e2-small \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=20GB \
  --tags=db-vm
```

## Step 2: Get Internal IPs

```bash
# Get all VM IPs
gcloud compute instances list

# Note down the INTERNAL_IP and EXTERNAL_IP for each VM:
# - jenkins-vm: INTERNAL_IP=10.160.0.4, EXTERNAL_IP=34.100.238.205
# - app-vm: INTERNAL_IP=10.160.0.5, EXTERNAL_IP=34.47.142.116
# - database-vm: INTERNAL_IP=10.160.0.6, EXTERNAL_IP=34.93.141.206
```

## Step 3: Setup Database VM

```bash
# SSH into database VM
gcloud compute ssh database-vm --zone=asia-south1-a

# Copy and run the setup script
curl -o database-vm-setup.sh https://raw.githubusercontent.com/HarshilForWork/Devops_MINI/main/deployment/database-vm-setup.sh
chmod +x database-vm-setup.sh
./database-vm-setup.sh

# After script completes, initialize database
docker cp ~/init.sql book_db:/init.sql
docker exec book_db sh -c 'mysql -uroot -p"Nitish@1234" book_db < /init.sql'

# Verify MySQL is running
docker ps
docker logs book_db

# Exit VM
exit
```

## Step 4: Setup Application VM

```bash
# SSH into app VM
gcloud compute ssh app-vm --zone=asia-south1-a

# Copy and run the setup script
curl -o app-vm-setup.sh https://raw.githubusercontent.com/HarshilForWork/Devops_MINI/main/deployment/app-vm-setup.sh
chmod +x app-vm-setup.sh
./app-vm-setup.sh

# IMPORTANT: Update the run command with DATABASE VM's INTERNAL IP
docker run -d \
  --name book_app \
  --restart always \
  -p 5000:5000 \
  -e MYSQL_HOST=10.160.0.6 \
  -e MYSQL_USER=root \
  -e MYSQL_PASSWORD=Nitish@1234 \
  -e MYSQL_DATABASE=book_db \
  -e SECRET_KEY=your-secret-key-here \
  gcr.io/cosmic-slate-469618-h1/book-manager-app:latest

# Configure Nginx reverse proxy
sudo nano /etc/nginx/sites-available/book-manager

# Add this configuration:
# server {
#     listen 80;
#     server_name YOUR_DOMAIN_OR_IP;
#
#     location / {
#         proxy_pass http://localhost:5000;
#         proxy_set_header Host $host;
#         proxy_set_header X-Real-IP $remote_addr;
#     }
# }

sudo ln -s /etc/nginx/sites-available/book-manager /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx

# Exit VM
exit
```

## Step 5: Setup Jenkins VM

```bash
# SSH into jenkins VM
gcloud compute ssh jenkins-vm --zone=asia-south1-a

# Copy and run the setup script
curl -o jenkins-vm-setup.sh https://raw.githubusercontent.com/HarshilForWork/Devops_MINI/main/deployment/jenkins-vm-setup.sh
chmod +x jenkins-vm-setup.sh
./jenkins-vm-setup.sh

# Get Jenkins initial password
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

# Exit VM
exit
```

## Step 6: Configure Jenkins Pipeline

1. **Access Jenkins**: `http://JENKINS_EXTERNAL_IP:8080`
2. **Install Plugins**:
   - Docker Pipeline
   - Git
   - SonarQube Scanner
   - Google Container Registry Auth

3. **Add Credentials**:
   - GitHub credentials (username/token)
   - GCP service account key
   - SSH keys for app-vm and database-vm

4. **Configure SonarQube**: `http://JENKINS_EXTERNAL_IP:9000`
   - Default credentials: admin/admin
   - Create project: book-manager
   - Generate token and add to Jenkins

5. **Create Pipeline**:
   - New Item → Pipeline
   - Pipeline from SCM → Git
   - Repository: `https://github.com/HarshilForWork/Devops_MINI.git`
   - Script Path: `Jenkinsfile`

## Step 7: Update Jenkinsfile for GCP

The Jenkinsfile needs to know the **app-vm's internal IP** to deploy via SSH:

```groovy
stage('Deploy to GCP') {
    steps {
        script {
            // SSH into app-vm and update container
            sh '''
                gcloud compute ssh app-vm --zone=asia-south1-a --command "
                    docker pull gcr.io/cosmic-slate-469618-h1/book-manager-app:latest
                    docker stop book_app || true
                    docker rm book_app || true
                    docker run -d --name book_app --restart always \
                      -p 5000:5000 \
                      -e MYSQL_HOST=10.160.0.6 \
                      -e MYSQL_USER=root \
                      -e MYSQL_PASSWORD=Nitish@1234 \
                      -e MYSQL_DATABASE=book_db \
                      gcr.io/cosmic-slate-469618-h1/book-manager-app:latest
                "
            '''
        }
    }
}
```

## How Containers Communicate in GCP

### Local Development (Docker Compose)
```
Frontend Container → Docker Network → MySQL Container
     (hostname: db)
```

### GCP Production (Multi-VM)
```
Flask Container (App VM) → GCP VPC → MySQL Container (Database VM)
  (IP: 10.160.0.6:3306)
```

### Key Points:
1. **No Docker Networking**: Containers are on different VMs, can't use Docker networks
2. **VM-to-VM Communication**: Uses GCP's internal network (10.128.0.x)
3. **Port Exposure Required**: MySQL must expose `-p 3306:3306` so App VM can connect
4. **Firewall Rules**: GCP firewall must allow port 3306 from app-vm to database-vm
5. **Environment Variables**: App container gets `MYSQL_HOST=10.160.0.6` (not `db`)

## Testing Connectivity

### From App VM, test database connection:
```bash
# SSH to app-vm
gcloud compute ssh app-vm --zone=asia-south1-a

# Install MySQL client
sudo apt-get install -y mysql-client

# Test connection to database VM
mysql -h 10.160.0.6 -uroot -pNitish@1234 -e "SHOW DATABASES;"

# Should see: book_db in the list
```

## Troubleshooting

### Can't connect to MySQL from App VM?
```bash
# Check firewall on Database VM
sudo ufw status

# Check MySQL is listening on all interfaces (not just localhost)
docker exec book_db mysql -uroot -p"Nitish@1234" -e "SHOW VARIABLES LIKE 'bind_address';"
# Should show: 0.0.0.0 or *
```

### Application can't reach database?
```bash
# Check environment variables in container
docker exec book_app env | grep MYSQL

# Check logs
docker logs book_app

# Test connection from inside container
docker exec -it book_app sh
ping 10.160.0.6
nc -zv 10.160.0.6 3306
```

## Cost Estimate (Monthly)

| VM | Machine Type | Hours/Month | Cost/Month |
|----|--------------|-------------|------------|
| Jenkins VM | e2-medium (2 vCPU, 4GB) | 730 | ~$30 |
| App VM | e2-micro (2 vCPU, 1GB) | 730 | ~$8 |
| Database VM | e2-small (2 vCPU, 2GB) | 730 | ~$17 |
| **Network egress** | | | ~$10 |
| **Storage** | 60GB total | | ~$6 |
| **Total** | | | **~$71/month** |

*Note: Prices are estimates and may vary by region.*

## Security Best Practices

1. **Database VM**: Only allow port 3306 from app-vm's IP
2. **Use secrets management**: Store passwords in GCP Secret Manager
3. **SSL/TLS**: Configure Nginx with Let's Encrypt certificates
4. **Regular backups**: Snapshot database VM disk weekly
5. **Update packages**: `sudo apt-get update && sudo apt-get upgrade` monthly

## Next Steps

1. Test local deployment with docker-compose
2. Create GCP VMs using commands above
3. Run setup scripts on each VM
4. Update Jenkinsfile with actual GCP project ID
5. Configure Jenkins pipeline
6. Set up GitHub webhook
7. Push code changes to trigger deployment

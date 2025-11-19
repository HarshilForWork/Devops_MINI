# Book Manager - DevOps Project

A full-stack web application for managing personal book collections with complete CI/CD pipeline deployment on GCP.

## 🏗️ Architecture

### **3-VM Setup on GCP:**

```
┌─────────────────────────────────────────────┐
│    VM 1: Jenkins + SonarQube               │
│    (CI/CD + Code Quality)                  │
└──────────────┬──────────────────────────────┘
               │ Deploys
     ┌─────────┴──────────┐
     │                    │
┌────▼─────────┐  ┌───────▼──────┐
│ VM 2:        │  │ VM 3:        │
│ Application  │  │ MySQL DB     │
│ (Full Stack) │  │              │
└──────────────┘  └──────────────┘
```

## 📁 Project Structure

```
Devops/
│
├── frontend/                       # Application (Full Stack)
│   ├── app.py                     # Flask application
│   ├── config.py                  # Configuration
│   ├── requirements.txt           # Python dependencies
│   ├── Dockerfile                 # Application container
│   ├── .dockerignore             # Docker exclusions
│   ├── static/                   # CSS, JS, images
│   │   └── styles.css
│   └── templates/                # Jinja2 HTML templates
│       ├── layout.html
│       ├── home.html
│       ├── login.html
│       ├── signup.html
│       ├── index.html
│       ├── add.html
│       └── edit.html
│
├── database/                       # Database scripts
│   ├── init.sql                   # Docker auto-init
│   ├── schema.sql                 # Production schema
│   └── README.md                  # Database documentation
│
├── deployment/                     # GCP VM setup scripts
│   ├── app-vm-setup.sh            # Application VM setup
│   ├── database-vm-setup.sh       # Database VM setup
│   └── jenkins-vm-setup.sh        # Jenkins/SonarQube VM setup
│
├── docker-compose.yml              # Local development setup
├── Jenkinsfile                     # CI/CD pipeline
├── sonar-project.properties        # SonarQube config
├── .dockerignore                   # Docker exclusions
├── .gitignore                      # Git exclusions
├── start.ps1                       # Quick start script
├── stop.ps1                        # Stop services script
└── README.md                       # This file
```

## 🚀 Local Development Setup

### **Prerequisites:**
- Docker Desktop installed
- Python 3.11+
- Git

### **Quick Start:**

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Technothinking/Book-Manager.git
   cd Book-Manager
   ```

2. **Start all services (Option 1 - Easy):**
   ```powershell
   .\start.ps1
   ```

3. **OR start with Docker Compose (Option 2):**
   ```bash
   docker-compose up -d
   ```

4. **Access the application:**
   - Application: http://localhost:5000
   - MySQL: localhost:3306
   - Test Login: test@example.com / test123

5. **Stop services:**
   ```powershell
   .\stop.ps1
   ```
   OR
   ```bash
   docker-compose down
   ```

## 🐳 Docker Commands

### **Build application image:**
```bash
cd frontend
docker build -t book-manager-app .
```

### **Run containers manually:**
```bash
# Database
docker run -d --name book_db \
  -e MYSQL_ROOT_PASSWORD=Nitish@1234 \
  -e MYSQL_DATABASE=book_db \
  -p 3306:3306 mysql:8.0

# Application
docker run -d --name book_app \
  -e MYSQL_HOST=db \
  -e MYSQL_USER=root \
  -e MYSQL_PASSWORD=Nitish@1234 \
  -e MYSQL_DB=book_db \
  -p 5000:5000 book-manager-app
```

## ☁️ GCP Deployment

### **1. Create GCP VMs:**
```bash
# Application VM
gcloud compute instances create app-vm \
  --machine-type=e2-small \
  --zone=us-central1-a \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud

# Database VM
gcloud compute instances create database-vm \
  --machine-type=e2-medium \
  --zone=us-central1-a \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud

# Jenkins + SonarQube VM
gcloud compute instances create jenkins-vm \
  --machine-type=e2-standard-2 \
  --zone=us-central1-a \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud
```

### **2. Run setup scripts on each VM:**
```bash
# SSH into each VM and run respective setup script
bash deployment/app-vm-setup.sh
bash deployment/database-vm-setup.sh
bash deployment/jenkins-vm-setup.sh
```

### **3. Configure Jenkins:**
- Install plugins: Docker, Git, SonarQube Scanner
- Add GitHub credentials
- Configure webhook: `http://your-jenkins-ip:8080/github-webhook/`
- Create pipeline from `Jenkinsfile`

## 📊 CI/CD Pipeline Flow

```
GitHub Push → Webhook → Jenkins
                           ↓
                   Pull Code from Git
                           ↓
                  SonarQube Analysis
                           ↓
                   Quality Gate Check
                           ↓
                    Build Docker Image
                           ↓
                 Push to Docker Registry
                           ↓
                Deploy to GCP App VM
                           ↓
                    Health Checks
                           ↓
                Notification (Success/Fail)
```

## 🗄️ Database Schema

### **Users Table:**
- id (INT, PK, AUTO_INCREMENT)
- name (VARCHAR)
- email (VARCHAR, UNIQUE)
- password (VARCHAR, hashed)
- created_at (TIMESTAMP)

### **Books Table:**
- id (INT, PK, AUTO_INCREMENT)
- title (VARCHAR)
- author (VARCHAR)
- user_id (INT, FK → users.id)
- created_at (TIMESTAMP)

## 🔧 Configuration

### **Environment Variables:**
Create `.env` file (for local development):
```env
MYSQL_HOST=localhost
MYSQL_USER=root
MYSQL_PASSWORD=Nitish@1234
MYSQL_DB=book_db
FLASK_ENV=development
```

## 📝 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Home page |
| GET/POST | `/signup` | User registration |
| GET/POST | `/login` | User authentication |
| GET | `/logout` | User logout |
| GET | `/dashboard` | User's book list |
| GET/POST | `/add` | Add new book |
| GET/POST | `/edit/<id>` | Edit book |
| GET | `/delete/<id>` | Delete book |

## 🛠️ Tech Stack

- **Backend:** Flask (Python)
- **Frontend:** Jinja2 Templates, Bootstrap, CSS
- **Database:** MySQL 8.0
- **Containerization:** Docker & Docker Compose
- **CI/CD:** Jenkins
- **Code Quality:** SonarQube
- **Cloud:** Google Cloud Platform (GCP)
- **Version Control:** Git/GitHub

## 💰 Cost Estimate (GCP)

| VM | Type | Monthly Cost (approx) |
|----|------|----------------------|
| Application VM | e2-small | ~$14 |
| Database VM | e2-medium | ~$28 |
| Jenkins VM | e2-standard-2 | ~$49 |
| **Total** | | **~$91/month** |

## 📚 Useful Commands

```bash
# View logs
docker-compose logs -f

# Rebuild and restart
docker-compose up -d --build

# Access MySQL
docker exec -it book_db mysql -uroot -p

# Check running containers
docker ps

# Remove all containers
docker-compose down -v
```

## 🔒 Security Notes

- Change default passwords before production
- Use environment variables for sensitive data
- Enable SSL/TLS for production
- Configure proper firewall rules
- Use GCP Secret Manager for credentials

## 📄 License

MIT License

## 👤 Author

Technothinking

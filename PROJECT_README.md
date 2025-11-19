# Book Manager - DevOps Project

A full-stack web application for managing personal book collections with complete CI/CD pipeline deployment on GCP.

## 🏗️ Architecture

### **4-VM Setup on GCP:**

```
┌─────────────────────────────────────────────┐
│    VM 1: Jenkins + SonarQube               │
│    (CI/CD + Code Quality)                  │
└──────────────┬──────────────────────────────┘
               │ Deploys
     ┌─────────┴──────────┬──────────────────┐
     │                    │                  │
┌────▼─────────┐  ┌──────▼──────┐  ┌───────▼──────┐
│ VM 2:        │  │ VM 3:       │  │ VM 4:        │
│ Frontend     │  │ Backend     │  │ MySQL DB     │
└──────────────┘  └─────────────┘  └──────────────┘
```

## 📁 Project Structure

```
Devops/
│
├── frontend/                       # Frontend Application
│   ├── app.py                     # Flask app with templates
│   ├── config.py                  # Configuration
│   ├── requirements.txt           # Python dependencies
│   ├── Dockerfile                 # Frontend container
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
├── backend/                        # Backend API
│   ├── app.py                     # Flask REST API
│   ├── config.py                  # Configuration
│   ├── requirements.txt           # Python dependencies
│   ├── Dockerfile                 # Backend container
│   └── .dockerignore             # Docker exclusions
│
├── database/                       # Database Scripts
│   ├── init.sql                   # Docker auto-init
│   ├── schema.sql                 # Production schema
│   └── README.md                  # DB documentation
│
├── deployment/                     # GCP VM Setup Scripts
│   ├── frontend-vm-setup.sh
│   ├── backend-vm-setup.sh
│   ├── database-vm-setup.sh
│   └── jenkins-vm-setup.sh
│
├── docker-compose.yml              # Local development setup
├── Jenkinsfile                     # CI/CD pipeline
├── sonar-project.properties        # SonarQube config
├── .dockerignore                   # Root Docker exclusions
├── .gitignore                      # Git exclusions
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

2. **Start all services with Docker Compose:**
   ```bash
   docker-compose up -d
   ```

3. **Access the application:**
   - Frontend: http://localhost:5000
   - Backend API: http://localhost:5001
   - MySQL: localhost:3306
   - Test Login: test@example.com / test123

4. **View logs:**
   ```bash
   docker-compose logs -f
   ```

5. **Stop services:**
   ```bash
   docker-compose down
   ```

## 🐳 Docker Commands

### **Build individual images:**

```bash
# Frontend
cd frontend
docker build -t book-manager-frontend .

# Backend
cd backend
docker build -t book-manager-backend .
```

### **Run containers manually:**

```bash
# Database
docker run -d --name book_db \
  -e MYSQL_ROOT_PASSWORD=Nitish@1234 \
  -e MYSQL_DATABASE=book_db \
  -p 3306:3306 mysql:8.0

# Backend
docker run -d --name book_backend \
  -e MYSQL_HOST=db \
  -p 5001:5000 book-manager-backend

# Frontend
docker run -d --name book_frontend \
  -p 5000:5000 book-manager-frontend
```

## ☁️ GCP Deployment

### **1. Create GCP VMs:**

```bash
# Frontend VM
gcloud compute instances create frontend-vm \
  --machine-type=e2-micro \
  --zone=us-central1-a \
  --image-family=ubuntu-2204-lts \
  --image-project=ubuntu-os-cloud

# Backend VM
gcloud compute instances create backend-vm \
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
bash deployment/frontend-vm-setup.sh
bash deployment/backend-vm-setup.sh
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
            Build Docker Images (parallel)
                           ↓
                 Push to Docker Registry
                           ↓
              Deploy to GCP VMs (parallel)
                           ↓
                    Health Checks
```

## 🗄️ Database Schema

### **Users Table:**
- id (INT, PK, AUTO_INCREMENT)
- name (VARCHAR)
- email (VARCHAR, UNIQUE)
- password (VARCHAR, hashed)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)

### **Books Table:**
- id (INT, PK, AUTO_INCREMENT)
- title (VARCHAR)
- author (VARCHAR)
- user_id (INT, FK → users.id)
- created_at (TIMESTAMP)
- updated_at (TIMESTAMP)

## 🔧 Configuration

### **Environment Variables:**

Create `.env` file for local development:

```env
# Database
MYSQL_HOST=localhost
MYSQL_USER=root
MYSQL_PASSWORD=Nitish@1234
MYSQL_DB=book_db

# Flask
FLASK_ENV=development
FLASK_DEBUG=True
```

## 📝 API Endpoints (Backend)

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/health` | Health check |
| POST | `/api/signup` | User registration |
| POST | `/api/login` | User authentication |
| POST | `/api/logout` | User logout |
| GET | `/api/books` | Get user's books |
| POST | `/api/books` | Add new book |
| PUT | `/api/books/<id>` | Update book |
| DELETE | `/api/books/<id>` | Delete book |

## 🎨 Frontend Routes

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/` | Home page |
| GET/POST | `/signup` | Registration page |
| GET/POST | `/login` | Login page |
| GET | `/logout` | Logout |
| GET | `/dashboard` | User dashboard |
| GET/POST | `/add` | Add book page |
| GET/POST | `/edit/<id>` | Edit book page |
| GET | `/delete/<id>` | Delete book |

## 🛠️ Tech Stack

- **Backend:** Flask (Python), Gunicorn
- **Frontend:** Flask, Jinja2 Templates, Bootstrap
- **Database:** MySQL 8.0
- **Containerization:** Docker
- **CI/CD:** Jenkins
- **Code Quality:** SonarQube
- **Cloud:** Google Cloud Platform (GCP)

## 📚 Useful Commands

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f [service_name]

# Rebuild and restart
docker-compose up -d --build

# Stop all services
docker-compose down

# Remove volumes (fresh start)
docker-compose down -v

# Access MySQL
docker exec -it book_db mysql -uroot -pNitish@1234 book_db

# Check running containers
docker ps

# Inspect container
docker inspect book_frontend
```

## 🔒 Security Notes

⚠️ **Before Production:**
- Change default passwords
- Use environment variables for secrets
- Enable SSL/TLS (HTTPS)
- Configure proper firewall rules
- Use GCP Secret Manager for credentials
- Enable CORS properly
- Implement rate limiting
- Add input validation
- Enable SQL injection protection

## 🧪 Testing

```bash
# Run backend tests
cd backend
pytest

# Check code quality locally
sonar-scanner
```

## 📄 License

MIT License

## 👤 Author

**Technothinking**
- GitHub: [@Technothinking](https://github.com/Technothinking)
- Repository: [Book-Manager](https://github.com/Technothinking/Book-Manager)

---

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

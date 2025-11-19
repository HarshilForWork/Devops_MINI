#!/bin/bash
# Application VM Setup Script for GCP

set -e

echo "===================================="
echo "Application VM Setup - Book Manager"
echo "===================================="

# Update system
echo "Updating system packages..."
sudo apt-get update && sudo apt-get upgrade -y

# Install Docker
echo "Installing Docker..."
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Add current user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose
echo "Installing Docker Compose..."
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Configure firewall
echo "Configuring firewall..."
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw allow 22/tcp

# Install Nginx (optional - for reverse proxy)
echo "Installing Nginx..."
sudo apt-get install -y nginx

# Create app directory
sudo mkdir -p /opt/book-manager
sudo chown $USER:$USER /opt/book-manager

echo "===================================="
echo "Application VM setup complete!"
echo "===================================="
echo "Next steps:"
echo "1. Get Database VM's internal IP (e.g., 10.128.0.4)"
echo "2. Pull Docker image: docker pull gcr.io/YOUR_PROJECT_ID/book-manager-app:latest"
echo "3. Run container with correct MYSQL_HOST:"
echo ""
echo "docker run -d \\"
echo "  --name book_app \\"
echo "  --restart always \\"
echo "  -p 5000:5000 \\"
echo "  -e MYSQL_HOST=10.128.0.4 \\"
echo "  -e MYSQL_USER=root \\"
echo "  -e MYSQL_PASSWORD=Nitish@1234 \\"
echo "  -e MYSQL_DATABASE=book_db \\"
echo "  -e SECRET_KEY=your-secret-key-here \\"
echo "  gcr.io/YOUR_PROJECT_ID/book-manager-app:latest"
echo ""
echo "4. Configure Nginx reverse proxy (see GCP_DEPLOYMENT_GUIDE.md)"
echo "5. Test: curl http://localhost:5000"

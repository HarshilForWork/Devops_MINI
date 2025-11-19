#!/bin/bash
# Database VM Setup Script for GCP

set -e

echo "===================================="
echo "Database VM Setup - Book Manager"
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

# Configure firewall
echo "Configuring firewall..."
sudo ufw allow 3306/tcp
sudo ufw allow 22/tcp

# Create MySQL data directory
sudo mkdir -p /opt/mysql/data
sudo mkdir -p /opt/mysql/init
sudo chown -R $USER:$USER /opt/mysql

# Pull MySQL Docker image
echo "Pulling MySQL 8.0 Docker image..."
docker pull mysql:8.0

echo "===================================="
echo "IMPORTANT: Copy init.sql to this VM"
echo "Run: gcloud compute scp database/init.sql database-vm:~/init.sql --zone=us-central1-a"
echo "Then continue with container creation"
echo "===================================="

# Create and start MySQL container
# NOTE: Port 3306 is exposed so App VM can connect over GCP internal network
echo "Starting MySQL container..."
docker run -d \
  --name book_db \
  --restart always \
  -e MYSQL_ROOT_PASSWORD=Nitish@1234 \
  -e MYSQL_DATABASE=book_db \
  -v /opt/mysql/data:/var/lib/mysql \
  -p 3306:3306 \
  mysql:8.0

# Wait for MySQL to start
echo "Waiting for MySQL to start..."
sleep 30

# Initialize database if init.sql exists
if [ -f ~/init.sql ]; then
  echo "Initializing database with init.sql..."
  docker cp ~/init.sql book_db:/init.sql
  docker exec book_db sh -c 'mysql -uroot -p"Nitish@1234" book_db < /init.sql'
  echo "Database initialized successfully!"
else
  echo "WARNING: init.sql not found. Database tables not created."
  echo "Copy init.sql and run: docker cp ~/init.sql book_db:/init.sql && docker exec book_db sh -c 'mysql -uroot -p\"Nitish@1234\" book_db < /init.sql'"
fi

echo "===================================="
echo "Database VM setup complete!"
echo "===================================="
echo "MySQL is running on port 3306"
echo "Root password: Nitish@1234"
echo "Database name: book_db"
echo ""
echo "To get this VM's internal IP:"
echo "  hostname -I | awk '{print \$1}'"
echo ""
echo "Testing MySQL connection:"
docker exec book_db mysql -uroot -p"Nitish@1234" -e "SHOW DATABASES;"
echo ""
echo "IMPORTANT: Use this VM's internal IP (e.g., 10.128.0.4) as MYSQL_HOST in App VM!"

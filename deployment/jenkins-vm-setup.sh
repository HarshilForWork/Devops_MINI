#!/bin/bash
# Jenkins + SonarQube VM Setup Script for GCP

set -e

echo "===================================="
echo "Jenkins + SonarQube VM Setup"
echo "===================================="

# Update system
echo "Updating system packages..."
sudo apt-get update && sudo apt-get upgrade -y

# Install Java (required for Jenkins and SonarQube)
echo "Installing Java..."
sudo apt-get install -y openjdk-17-jdk

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

# Install Jenkins
echo "Installing Jenkins..."
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install -y jenkins

# Start Jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Install SonarQube using Docker
echo "Installing SonarQube..."
docker run -d \
  --name sonarqube \
  --restart always \
  -p 9000:9000 \
  -e SONAR_ES_BOOTSTRAP_CHECKS_DISABLE=true \
  sonarqube:latest

# Configure firewall
echo "Configuring firewall..."
sudo ufw allow 8080/tcp  # Jenkins
sudo ufw allow 9000/tcp  # SonarQube
sudo ufw allow 22/tcp

# Install Git
echo "Installing Git..."
sudo apt-get install -y git

# Install gcloud CLI
echo "Installing Google Cloud SDK..."
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" | sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
sudo apt-get update && sudo apt-get install -y google-cloud-cli

echo "===================================="
echo "Jenkins + SonarQube VM setup complete!"
echo "===================================="
echo ""
echo "Jenkins URL: http://YOUR_VM_IP:8080"
echo "Initial admin password: sudo cat /var/lib/jenkins/secrets/initialAdminPassword"
echo ""
echo "SonarQube URL: http://YOUR_VM_IP:9000"
echo "Default credentials: admin/admin"
echo ""
echo "Next steps:"
echo "1. Access Jenkins and complete setup wizard"
echo "2. Install required Jenkins plugins (Docker, Git, SonarQube Scanner)"
echo "3. Configure GitHub webhook"
echo "4. Set up SonarQube project"
echo "5. Create Jenkins pipeline from Jenkinsfile"

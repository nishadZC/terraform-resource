#!/bin/bash
set -e

echo "Updating system packages..."
sudo apt update

echo "Installing Java 21 and required packages..."
sudo apt install -y fontconfig openjdk-21-jre wget curl unzip gnupg lsb-release ca-certificates

# Install Jenkins
echo "Waiting for 30 seconds before installing Jenkins..."
sleep 30

sudo mkdir -p /etc/apt/keyrings

sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/" | \
sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt update
sudo apt install -y jenkins

sudo systemctl enable jenkins
sudo systemctl start jenkins


# Install Docker
echo "Installing Docker..."

curl -fsSL https://get.docker.com | sudo sh

sudo systemctl enable docker
sudo systemctl start docker

# Add Jenkins user to Docker group
sudo usermod -aG docker jenkins

# (Optional) Add current user to Docker group
sudo usermod -aG docker $USER


# Install Terraform
echo "Waiting for 30 seconds before installing Terraform..."
sleep 30

wget https://releases.hashicorp.com/terraform/1.15.6/terraform_1.15.6_linux_amd64.zip

unzip terraform_1.15.6_linux_amd64.zip

sudo mv terraform /usr/local/bin/

terraform -version


# Install AWS CLI v2
echo "Installing AWS CLI..."

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

unzip awscliv2.zip

sudo ./aws/install

aws --version

# Restart Jenkins
sudo systemctl restart jenkins

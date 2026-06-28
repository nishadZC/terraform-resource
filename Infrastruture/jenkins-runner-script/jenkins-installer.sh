#!/bin/bash
sudo apt update
sudo apt install fontconfig openjdk-21-jre -y
echo "Waiting for 30 seconds before installing the jenkins package..."
sleep 30
sudo wget -O /etc/apt/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key
echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt update
sudo apt install jenkins -y
sleep 30
echo "Waiting for 30 seconds before installing the Terraform..."
wget https://releases.hashicorp.com/terraform/1.15.6/terraform_1.15.6_linux_amd64.zip
yes | sudo apt-get install unzip
unzip 'terraform*.zip'
sudo mv terraform /usr/local/bin/
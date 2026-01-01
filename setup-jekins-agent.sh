#!/bin/bash
# Jenkins Agent Setup Script for Docker + Compose
# Tested on Ubuntu 20.04/22.04

set -e

echo "=== Updating system packages ==="
sudo apt-get update -y
sudo apt-get upgrade -y

echo "=== Installing required packages ==="
sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    gnupg \
    lsb-release

echo "=== Installing Docker Engine ==="
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] \
  https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
  | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

echo "=== Installing Docker Compose plugin ==="
sudo apt-get install -y docker-compose-plugin

echo "=== Adding Jenkins user to docker group ==="
sudo usermod -aG docker jenkins

echo "=== Restarting Docker and Jenkins services ==="
sudo systemctl enable docker
sudo systemctl start docker
sudo systemctl restart jenkins

echo "=== Setup complete ==="
echo "Verify by running: 'docker --version' and 'docker compose version' as the jenkins user."
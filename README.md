# DevOps Project Report: Automated CI/CD Pipeline for a 2-Tier Flask Application on AWS

**Author:** Sandeep Thontla
**Date:** Jan 01, 2026

---

### **Table of Contents**
1. [Project Overview](#1-project-overview)
2. [Architecture Diagram](#2-architecture-diagram)
3. [Step 1: AWS EC2 Instance Preparation](#3-step-1-aws-ec2-instance-preparation)
4. [Step 2: Install Dependencies on EC2](#4-step-2-install-dependencies-on-ec2)
5. [Step 3: Jenkins Installation and Setup](#5-step-3-jenkins-installation-and-setup)
6. [Step 4: GitHub Repository Configuration](#6-step-4-github-repository-configuration)
    * [Dockerfile](#dockerfile)
    * [docker-compose.yml](#docker-composeyml)
    * [Jenkinsfile](#jenkinsfile)
7. [Step 5: Jenkins Pipeline Creation and Execution](#7-step-5-jenkins-pipeline-creation-and-execution)
8. [Conclusion](#8-conclusion)
9. [Infrastructure Diagram](#9-infrastructure-diagram)
10. [Work flow Diagram](#10-work-flow-diagram)

---

### **1. Project Overview**
---
This project demonstrates the deployment and automation of a two-tier web application built with Flask and MySQL on AWS EC2. The application is containerized using Docker and orchestrated with Docker Compose, providing portability, consistency, and efficient resource utilization across environments. To streamline the software delivery lifecycle, a CI/CD pipeline is integrated with Jenkins, automatically triggering builds and deployments whenever changes are committed to GitHub.

The implementation showcases key DevOps practices, including continuous integration, continuous deployment, and infrastructure automation. By leveraging cloud infrastructure, containerization, and CI/CD tooling, the solution reduces manual effort, minimizes deployment risks, and enhances application reliability and scalability. This approach ensures faster delivery cycles and improved operational efficiency.

Designed and executed by Sandeep Thontla, the project reflects strong expertise in cloud computing and DevOps engineering, highlighting practical skills in automation, pipeline design, and modern application deployment strategies.

---

### **2. Architecture Diagram**
---
<img width="1024" height="1536" alt="project-workflow" src="https://github.com/user-attachments/assets/b098b112-a52c-4028-9b0e-0a555674cc05" />


---

### **3. Step 1: AWS EC2 Instance Preparation**

1.  **Launch EC2 Instance:**
    * Navigate to the AWS EC2 console.
    * Launch a new instance using the **Ubuntu 22.04 LTS** AMI.
    * Select the **t2.micro** instance type for free-tier eligibility.
    * Create and assign a new key pair for SSH access.

<img width="1897" height="797" alt="01" src="https://github.com/user-attachments/assets/f5c1d9ab-0ea6-47b0-a3eb-7ee6df4cf3d1" />


2.  **Configure Security Group:**
    * Create a security group with the following inbound rules:
        * **Type:** SSH, **Protocol:** TCP, **Port:** 22, **Source:** Your IP
        * **Type:** HTTP, **Protocol:** TCP, **Port:** 80, **Source:** Anywhere (0.0.0.0/0)
        * **Type:** Custom TCP, **Protocol:** TCP, **Port:** 5000 (for Flask), **Source:** Anywhere (0.0.0.0/0)
        * **Type:** Custom TCP, **Protocol:** TCP, **Port:** 8080 (for Jenkins), **Source:** Anywhere (0.0.0.0/0)

<img width="1911" height="742" alt="02" src="https://github.com/user-attachments/assets/4622c34b-4931-41b1-a01d-5d0cfc462e77" />


3.  **Connect to EC2 Instance:**
    * Use SSH to connect to the instance's public IP address.
    ```bash
    ssh -i /path/to/key.pem ubuntu@<ec2-public-ip>
    ```

---

### **4. Step 2: Install Dependencies on EC2**

1.  **Update System Packages:**
    ```bash
    sudo apt update && sudo apt upgrade -y
    ```

2.  **Install Git, Docker, and Docker Compose:**
    ```bash
    sudo apt install git docker.io docker-compose-v2 -y
    ```

3.  **Start and Enable Docker:**
    ```bash
    sudo systemctl start docker
    sudo systemctl enable docker
    ```

4.  **Add User to Docker Group (to run docker without sudo):**
    ```bash
    sudo usermod -aG docker $USER
    newgrp docker
    ```

---

### **5. Step 3: Jenkins Installation and Setup**

1.  **Install Java (OpenJDK 17):**
    ```bash
    sudo apt install openjdk-17-jdk -y
    ```

2.  **Add Jenkins Repository and Install:**
    ```bash
    curl -fsSL [https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key](https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key) | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
    echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] [https://pkg.jenkins.io/debian-stable](https://pkg.jenkins.io/debian-stable) binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
    sudo apt update
    sudo apt install jenkins -y
    ```

3.  **Start and Enable Jenkins Service:**
    ```bash
    sudo systemctl start jenkins
    sudo systemctl enable jenkins
    ```

4.  **Initial Jenkins Setup:**
    * Retrieve the initial admin password:
        ```bash
        sudo cat /var/lib/jenkins/secrets/initialAdminPassword
        ```
    * Access the Jenkins dashboard at `http://<ec2-public-ip>:8080`.
    * Paste the password, install suggested plugins, and create an admin user.

5.  **Grant Jenkins Docker Permissions:**
    ```bash
    sudo usermod -aG docker jenkins
    sudo systemctl restart jenkins
    ```
<img width="1236" height="870" alt="03" src="https://github.com/user-attachments/assets/66681962-60d4-4abe-8b82-4c0931bb326d" />


---

### **6. Step 4: GitHub Repository Configuration**

Ensure your GitHub repository contains the following three files.

#### **Dockerfile**
This file defines the environment for the Flask application container.
```dockerfile
# Use an official Python runtime as a parent image
FROM python:3.9-slim

# Set the working directory in the container
WORKDIR /app

# Install system dependencies required for mysqlclient
RUN apt-get update && apt-get install -y gcc default-libmysqlclient-dev pkg-config && \
    rm -rf /var/lib/apt/lists/*

# Copy the requirements file to leverage Docker cache
COPY requirements.txt .

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application code
COPY . .

# Expose the port the app runs on
EXPOSE 5000

# Command to run the application
CMD ["python", "app.py"]
```

#### **docker-compose.yml**
This file defines and orchestrates the multi-container application (Flask and MySQL).
```yaml
version: "3.8"

services:
  mysql:
    container_name: mysql
    image: mysql
    environment:
      MYSQL_ROOT_PASSWORD: "root"
      MYSQL_DATABASE: "devops"
    ports:
      - "3306:3306"

    volumes:
      - mysql_data:/var/lib/mysql

    networks:
      - two-tier-nt

    restart: always
    healthcheck:
      test: ["CMD-SHELL", "mysqladmin ping -h localhost -p$MYSQL_ROOT_PASSWORd"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 60s




  flask-app:
    container_name: two-tier-app
    build:
      context: .

    ports:
      - "5000:5000"

    environment:
      - MYSQL_HOST=mysql
      - MYSQL_USER=root
      - MYSQL_PASSWORD=root
      - MYSQL_DB=devops

    networks:
      - two-tier-nt

    depends_on:
      mysql:
        condition: service_healthy

    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:5000/health || exit 1"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 60s

volumes:
  mysql_data:

networks:
  two-tier-nt:
```

#### **Jenkinsfile**
This file contains the pipeline-as-code definition for Jenkins.
```groovy
pipeline{
    agent any
    stages{
        stage('Clone repo'){
            steps{
                git branch: 'main', url: 'https://github.com/Sandeept1986-web/DevOps-Project-Two-Tier-Flask-App.git'
            }
        }
        stage('Build image'){
            steps{
                sh 'docker build -t flask-app .'
            }
        }
        stage('Deploy with docker compose'){
            steps{
                // existing container if they are running
                sh 'docker compose down || true'
                // start app, rebuilding flask image
                sh 'docker compose up -d --build'
            }
        }
    }
}
```

---

### **7. Step 5: Jenkins Pipeline Creation and Execution**

1.  **Create a New Pipeline Job in Jenkins:**
    * From the Jenkins dashboard, select **New Item**.
    * Name the project, choose **Pipeline**, and click **OK**.

2.  **Configure the Pipeline:**
    * In the project configuration, scroll to the **Pipeline** section.
    * Set **Definition** to **Pipeline script from SCM**.
    * Choose **Git** as the SCM.
    * Enter your GitHub repository URL.
    * Verify the **Script Path** is `Jenkinsfile`.
    * Save the configuration.

<img width="1900" height="902" alt="04" src="https://github.com/user-attachments/assets/813b48e3-1663-4ce0-9c79-fdee05037f0d" />


3.  **Run the Pipeline:**
    * Click **Build Now** to trigger the pipeline manually for the first time.
    * Monitor the execution through the **Stage View** or **Console Output**.

<img width="1430" height="812" alt="05" src="https://github.com/user-attachments/assets/deb4b9e5-4e09-46f1-987b-a6aea2b06198" />
<img width="1397" height="732" alt="06" src="https://github.com/user-attachments/assets/9160242c-ce16-4af5-8de2-41b21ede2d18" />



4.  **Verify Deployment:**
    * After a successful build, your Flask application will be accessible at `http://<your-ec2-public-ip>:5000`.
    * Confirm the containers are running on the EC2 instance with `docker ps`.
<img width="1850" height="907" alt="07" src="https://github.com/user-attachments/assets/ce278649-085d-4160-92eb-887006b64441" />
---

### **8. Conclusion**
The CI/CD pipeline is now fully operational. Any `git push` to the `main` branch of the configured GitHub repository will automatically trigger the Jenkins pipeline, which will build the new Docker image and deploy the updated application, ensuring a seamless and automated workflow from development to production.


### **9. Infrastructure Diagram**
<img width="1024" height="1024" alt="Infrastructure" src="https://github.com/user-attachments/assets/e3aefc60-e049-4f78-95b7-20b418be9bbb" />



### **10. Work flow Diagram**
<img width="1024" height="1536" alt="project-workflow" src="https://github.com/user-attachments/assets/48ec52c8-42af-44ec-a4b2-528b88e55cce" />


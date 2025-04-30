# AWS Infrastructure Automation Project

## 📚 Overview

This project demonstrates the complete Infrastructure as Code (IaC) and Continuous Deployment (CD) pipeline for deploying a highly available WordPress application on AWS using:

- 🚀 Terraform: Infrastructure provisioning
- 🔧 Ansible: Application configuration & deployment
- 🔄 Jenkins: Automation and CI/CD orchestration

---

## ☐ Architecture Summary

The infrastructure includes:

- A custom VPC with:
  - 2 public subnets (in different AZs)
  - 2 private subnets (in different AZs)
- Internet Gateway and NAT Gateway
- Application Load Balancer (ALB)
- Two EC2 instances in private subnets (WordPress)
- VPC Peering to default VPC
- Routing configuration for inter-VPC communication
- Security groups for EC2 and ALB
- Automated deployment using Jenkins pipeline

📌 Visual diagram: See `architecture.png` for a full visual representation.

---

## 📁 Project Structure

```
.
├── terraform/              # Terraform code for AWS infrastructure
│   ├── main.tf
│   ├── variables.tf
│   ├── terraform.tfvars
│   ├── provider.tf
│   └── outputs.tf
├── ansible/                # Ansible playbooks and inventory
│   ├── mywebsite.yaml
│   └── inventory.ini
├── jenkins/                # Jenkinsfile
│   └── Jenkinsfile
└── README.md
```

---

## ⚙️ Terraform: Infrastructure Provisioning

### VPC and Subnets

- A custom VPC (`10.0.0.0/16`)
- Two public subnets:
  - `10.0.1.0/24` in `us-east-1a`
  - `10.0.2.0/24` in `us-east-1b`
- Two private subnets:
  - `10.0.3.0/24` in `us-east-1a`
  - `10.0.4.0/24` in `us-east-1b`

### Internet Gateway & NAT Gateway

- IGW for outbound internet from public subnets
- NAT Gateway in a public subnet allows EC2 instances in private subnets to access the internet

### Route Tables

- Public route table associated with public subnets → routes 0.0.0.0/0 to IGW
- Private route table associated with private subnets → routes 0.0.0.0/0 to NAT Gateway

### Load Balancer & Target Group

- ALB spans both public subnets
- Targets are EC2 instances in private subnets
- HTTP listener configured

### Security Groups

- ALB SG: Allows HTTP/HTTPS from anywhere
- EC2 SG: Allows HTTP from ALB and SSH from allowed IP

### EC2 Instances

- Two EC2s deployed in private subnets
- Amazon Linux 2
- Automatically attached to the ALB target group

### VPC Peering

- Connects custom VPC to AWS default VPC
- Routes updated on both sides to enable private communication

---

## 🔧 Ansible: WordPress Deployment

Ansible handles software installation and configuration:

- WordPress installed on EC2s
- PHP, MySQL clients, Apache/Nginx installed
- Playbook `mywebsite.yaml` executed via Jenkins
- Dynamic inventory generated from Terraform outputs

---

## 🔄 Jenkins: CI/CD Automation

Pipeline automates:

1. Terraform initialization, plan, and apply
2. Captures EC2 private IPs and generates Ansible inventory
3. Injects SSH key securely from Jenkins credentials store
4. Runs Ansible playbook to deploy WordPress

---

## ✅ Prerequisites

- AWS Account & IAM credentials
- Jenkins with:
  - AWS credentials configured
  - SSH private key credentials for Ansible
  - GitHub integration
- Terraform and Ansible installed on Jenkins agent
- SSH key pair (`p-key`) created and available in AWS

---

## 🚀 How to Run

1. Clone the repo:

   ```bash
   git clone https://github.com/aya-63/Wordpress_Deployment-with-jenkins-.git
   cd aws-wordpress-infra
   ```

2. Update `terraform.tfvars` with your own values

3. Push to GitHub to trigger Jenkins, or manually run the Jenkins pipeline

4. After execution, access the application via the Load Balancer DNS:

   ```bash
   terraform output load_balancer_dns_name
   ```

---

## 📤 Outputs

- ALB DNS (used to access the WordPress site)
- Private IPs of EC2 instances
- VPC Peering Connection ID

---

---

## 📦 Future Enhancements

- Add RDS database and configure WordPress to use it
- Add Auto Scaling Group (ASG)
- Use S3 and CloudFront for static assets
- CI/CD for WordPress code updates

---

##


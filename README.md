# terraform-notes-app
Learning project using Terraform / AWS / GitHub Actions / Flask / Elasticsearch

This project provisions and deploys a simple Notes application using Terraform and AWS. It demonstrates Infrastructure as Code (IaC) practices for running a Python Flask app with Elasticsearch behind a load-balanced, secure infrastructure.

I am using this for learning purposes and adding more components and features as I go... 

# Architecture Overview

* Flask Web App (Python) – Allows users to create and search notes - very simple app just used for demo purposes
* Terraform – Manages infrastructure as code
* GitHub Actions for Terraform automation (with Terraform Cloud)
* AWS Services Used:
  * EC2 (Ubuntu host running Docker containers)
  * Application Load Balancer (ALB) with HTTPS support
  * Security Groups
  * VPC and Subnets (default VPC used for now)
  * user_data script for EC2 initialization
  * OpenSearch for full-text search functionality
  * RDS PostgreSQL for user account handling
  * ACM (AWS Certificate Manager) for SSL certificates
  * IAM Roles for secure access to AWS services (Opensearch)

# Structure

```
├── LICENSE
├── main.tf
├── modules
│   ├── acm
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── alb
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── ec2-instance
│   │   ├── files
│   │   │   └── user_data.sh.tmpl
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── iam
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── opensearch
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── rds-pg
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   ├── security_groups
│   │   ├── main.tf
│   │   ├── outputs.tf
│   │   └── variables.tf
│   └── vpc
│       ├── main.tf
│       └── outputs.tf
├── notes_app
│   ├── Dockerfile
│   ├── notes.py
│   ├── requirements.txt
│   ├── templates
│   │   ├── layout.html
│   │   ├── login.html
│   │   ├── new_note.html
│   │   ├── notes.html
│   │   └── register.html
│   └── terraform.tfstate
├── outputs.tf
├── providers.tf
├── README.md
└── variables.tf
```



# Current Features

* One-click provisioning of the app and its dependencies using Terraform and GitHub Actions.
* Secure and isolated EC2 instance(s) with custom Security Groups.
* ALB with automatic HTTPS via ACM
* Deployment is handled by user_data, which launches prebuilt Docker containers for the app and search backend.
* Application is exposed via an AWS Application Load Balancer (ALB) with HTTPS support.
* Modularized Terraform code for clean structure and reusability.
* Configurable number of EC2 instances and AZ distribution (via instance_count var).


# Planned Features

At the moment I'm planning on adding these:
* Add monitoring and alerting (e.g. CloudWatch, Prometheus)
* Implement blue/green or canary deployments for safer rollouts
* Create a custom VPC to use instead of default

# Usage
```
terraform init
terraform plan
terraform apply
```
Ensure your AWS credentials are properly set (via environment or CLI) and you have access to required services (EC2, ALB, ACM, IAM).

# Requirements

* Terraform 1.2+
* AWS CLI
* Docker
* Teraform cloud account
* Ubuntu AMI (required for EC2 user_data compatibility)




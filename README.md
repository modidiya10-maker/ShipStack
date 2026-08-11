# ShipStack

**Infrastructure as Code deployment of a Python web service on AWS.**

ShipStack provisions AWS infrastructure with Terraform and deploys a Flask application to an EC2 instance. The application is automatically configured during instance startup using EC2 user data.

[![CI](https://github.com/modidiya10-maker/ShipStack/actions/workflows/ci.yml/badge.svg)](https://github.com/modidiya10-maker/ShipStack/actions)

---

## Overview

ShipStack demonstrates a reproducible cloud deployment workflow:

**Python Application → Automated Tests → GitHub Actions → Terraform → AWS → Running Service**

Instead of manually configuring an EC2 server, the required AWS infrastructure is defined as code and the application server configures itself during startup.

### What it demonstrates

- Infrastructure as Code with Terraform
- AWS VPC networking
- EC2 provisioning
- Automated server bootstrap
- Flask application deployment
- Automated testing with pytest
- Continuous Integration with GitHub Actions
- Git and GitHub based workflow

---

## Architecture

```text
                         GitHub
                            │
              ┌─────────────┴─────────────┐
              │                           │
        Application Code             Terraform
              │                           │
              ▼                           ▼
          Flask + pytest             AWS VPC
                                          │
                               ┌──────────┴──────────┐
                               │                     │
                         Public Subnet        Internet Gateway
                               │
                               ▼
                        Security Group
                               │
                               ▼
                              EC2
                               │
                         EC2 User Data
                               │
                    ┌──────────┴──────────┐
                    │                     │
               Clone Repository     Install Dependencies
                    │                     │
                    └──────────┬──────────┘
                               │
                            Gunicorn
                               │
                            Flask API
                               │
                             HTTP :80
AWS Infrastructure

Terraform manages the following resources:

Resource	Purpose
VPC	Provides the isolated AWS network
Public Subnet	Hosts the EC2 instance
Internet Gateway	Provides internet connectivity
Route Table	Routes public traffic
Route Association	Associates the subnet with the route table
Security Group	Controls network access
EC2 Instance	Runs the ShipStack application

Terraform configuration:

infrastructure/main.tf

Deployment Flow

When the infrastructure is provisioned:

Terraform
    │
    ▼
Create AWS Infrastructure
    │
    ▼
Launch EC2 Instance
    │
    ▼
Run User Data
    │
    ├── Install Python
    ├── Install Git
    ├── Clone ShipStack
    ├── Create virtual environment
    ├── Install dependencies
    └── Start Gunicorn
    │
    ▼
Flask API available on HTTP :80

This makes the server setup reproducible instead of relying on manual configuration.

Application

ShipStack is a lightweight Flask service.

Endpoint
GET /
Response
{
  "message": "Application is running",
  "service": "ShipStack"
}
Technology Stack
Category	Technology
Language	Python
Web Framework	Flask
Application Server	Gunicorn
Testing	pytest
CI	GitHub Actions
Infrastructure as Code	Terraform
Cloud	AWS
Compute	EC2
Networking	VPC
Operating System	Ubuntu
Project Structure
ShipStack/
│
├── .github/
│   └── workflows/
│       └── ci.yml
│
├── app/
│   ├── __init__.py
│   ├── app.py
│   └── requirements.txt
│
├── tests/
│   └── test_app.py
│
├── infrastructure/
│   ├── main.tf
│   └── .terraform.lock.hcl
│
├── .gitignore
├── LICENSE
└── README.md
Local Setup
Prerequisites
Python 3.x
Git
Terraform
AWS CLI
Clone the repository
git clone https://github.com/modidiya10-maker/ShipStack.git
cd ShipStack
Install dependencies
python -m pip install -r app/requirements.txt
Run tests
python -m pytest

Expected result:

3 passed
Run the application
python app/app.py
AWS Deployment

Navigate to the Terraform configuration:

cd infrastructure

Initialize Terraform:

terraform init

Validate the configuration:

terraform validate

Review the proposed infrastructure:

terraform plan

Provision the infrastructure:

terraform apply

To remove the infrastructure:

terraform destroy

AWS resources may incur charges. Destroy the infrastructure when it is no longer required.

CI

GitHub Actions automatically runs the test suite when changes are pushed to the repository.

Git Push
   │
   ▼
GitHub Actions
   │
   ▼
Install Dependencies
   │
   ▼
Run pytest
   │
   ▼
Pass / Fail

Workflow:

.github/workflows/ci.yml

Security

The current deployment exposes only the HTTP endpoint required by the application.

HTTP port 80 is publicly accessible.
SSH is not publicly exposed.
Terraform state files are excluded from Git.
.terraform/ is excluded from Git.
AWS credentials are not stored in the repository.
Project Status
Component	Status
Flask Application	Complete
Automated Tests	Complete
GitHub Actions CI	Complete
Terraform Infrastructure	Complete
AWS Deployment	Complete
EC2 Bootstrap	Complete
Future Improvements
HTTPS and domain-based access
CloudWatch monitoring
Centralized application logging
Docker-based deployment
Remote Terraform state
Automated deployment through CI/CD
Application Load Balancer
Auto Scaling
License

This project is licensed under the MIT License. See LICENSE for details.

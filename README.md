ShipStack
Infrastructure-as-Code deployment pipeline for a Python web service on AWS

ShipStack is a deployment-focused project that provisions AWS infrastructure with Terraform and automatically deploys a Flask API to an EC2 instance.

The project demonstrates the complete path from application source code to a publicly accessible cloud service:

Code → Tests → CI → Infrastructure → Server Provisioning → Application

Live Deployment

Service: ShipStack
Platform: AWS EC2
Region: ap-south-1

Health Check
GET /

Response:

{
  "message": "Application is running",
  "service": "ShipStack"
}
Why ShipStack?

Deploying a Python application manually involves configuring a server, networking, security rules, dependencies, and the application runtime.

ShipStack automates that process.

Instead of manually creating infrastructure through the AWS Console, Terraform defines the infrastructure as code. When the EC2 instance starts, a bootstrap script installs the required software, retrieves the application from GitHub, installs dependencies, and starts the service with Gunicorn.

The result is a repeatable deployment process rather than a manually configured server.

Architecture
                         GitHub
                           │
                    Application Code
                           │
             ┌─────────────┴─────────────┐
             │                           │
        GitHub Actions                Terraform
             │                           │
          pytest                    AWS Infrastructure
             │                           │
             └─────────────┬─────────────┘
                           │
                        AWS VPC
                           │
                    Public Subnet
                           │
              ┌────────────┴────────────┐
              │                         │
       Internet Gateway           Security Group
              │                         │
              └────────────┬────────────┘
                           │
                        EC2
                     Ubuntu Server
                           │
                    EC2 User Data
                           │
              ┌────────────┴────────────┐
              │                         │
          Clone Repo             Install Dependencies
              │                         │
              └────────────┬────────────┘
                           │
                       Gunicorn
                           │
                       Flask API
                           │
                        HTTP :80
What is Provisioned?

Terraform currently manages:

Resource	Purpose
VPC	Isolated AWS network
Public Subnet	Network segment for the application server
Internet Gateway	Internet connectivity
Route Table	Routes public traffic
Route Association	Associates subnet with public routing
Security Group	Controls inbound/outbound traffic
EC2 Instance	Hosts the application

The infrastructure is defined in:

infrastructure/main.tf
Application Stack
Python
└── Flask
    └── Gunicorn

Testing:

pytest

Infrastructure:

Terraform
└── AWS
    ├── VPC
    ├── Subnet
    ├── Internet Gateway
    ├── Route Table
    ├── Security Group
    └── EC2

CI:

GitHub Actions
└── pytest
Repository Structure
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
Local Development
Requirements
Python 3
Git
Terraform
AWS CLI
Clone
git clone https://github.com/modidiya10-maker/ShipStack.git
cd ShipStack
Install dependencies
python -m pip install -r app/requirements.txt
Run tests
python -m pytest
Run locally
python app/app.py
Infrastructure Deployment

Terraform manages the AWS environment.

Initialize:

terraform init

Validate:

terraform validate

Preview infrastructure changes:

terraform plan

Provision:

terraform apply

Destroy when finished:

terraform destroy

Note: AWS resources may incur charges. Destroy the infrastructure when it is no longer required.

Deployment Automation

The EC2 instance uses user data during initialization.

The bootstrap process:

EC2 starts
   ↓
Install Python + Git
   ↓
Clone ShipStack
   ↓
Create virtual environment
   ↓
Install requirements
   ↓
Start Gunicorn
   ↓
Expose Flask API on port 80

This removes the need to manually configure the application server after provisioning.

CI Pipeline

Every repository change is checked through GitHub Actions.

Push
  ↓
GitHub Actions
  ↓
Install dependencies
  ↓
Run pytest
  ↓
Pass / Fail

The CI workflow is located at:

.github/workflows/ci.yml
Testing

The project currently contains automated tests for the Flask application.

Run:

python -m pytest

Expected result:

3 passed
Security

The deployed security group currently exposes:

HTTP  → TCP 80 → Internet

SSH is not publicly exposed.

Terraform state and local Terraform working files are excluded from Git to avoid committing infrastructure state into the repository.

AWS credentials are not stored in the source code.

Current Status

Deployment: Working
Infrastructure: Terraform-managed
Application: Running on AWS EC2
CI: Configured
Tests: Passing

Roadmap

ShipStack is intentionally kept small enough to understand while leaving room for future infrastructure improvements.

Potential next iterations:

 HTTPS / TLS
 Domain-based access
 Docker-based deployment
 Remote Terraform state
 CI/CD deployment workflow
 Application logging
 CloudWatch monitoring
 Load balancing
 Auto Scaling
License

This project is licensed under the MIT License. See LICENSE for details.

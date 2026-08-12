# ShipStack

### Infrastructure-as-Code CI/CD pipeline for deploying a Python web service on AWS

ShipStack is a deployment-focused DevOps project that automates the path from application source code to a publicly accessible Flask service running on AWS EC2.

The project combines **Python, Flask, pytest, GitHub Actions, Terraform, AWS IAM OIDC, Amazon S3 remote state, VPC networking, EC2, and Gunicorn** into a repeatable deployment workflow.

```text
Code
  ↓
Tests
  ↓
GitHub Actions
  ↓
AWS OIDC
  ↓
Terraform
  ↓
AWS Infrastructure
  ↓
EC2 Bootstrap
  ↓
Gunicorn
  ↓
Flask API
```

---

## Why ShipStack?

Deploying a web application manually requires configuring networking, compute, security rules, dependencies, and the application runtime.

ShipStack automates these infrastructure and deployment steps using Infrastructure as Code.

Instead of manually creating AWS resources through the console:

* Terraform defines the infrastructure.
* GitHub Actions validates application changes.
* GitHub authenticates to AWS through OIDC instead of storing long-lived AWS access keys.
* Terraform state is stored remotely in Amazon S3.
* EC2 bootstraps the application automatically through User Data.
* Gunicorn serves the Flask application.
* Production infrastructure changes require an explicit deployment workflow and environment approval.

The result is a repeatable and auditable deployment process rather than a manually configured server.

---

## Architecture

```text
                              Developer
                                  │
                                  ▼
                              GitHub
                                  │
                 ┌────────────────┴────────────────┐
                 │                                 │
             Push / PR                    Manual Deployment
                 │                                 │
                 ▼                                 ▼
          GitHub Actions                    workflow_dispatch
                 │                                 │
                 ▼                                 ▼
              pytest                           Terraform
                 │                              Plan
                 ▼                                 │
          AWS OIDC Authentication                  │
                 │                                 │
                 ▼                                 ▼
       ShipStack-GitHubActions              Production
             IAM Role                        Approval
                 │                                 │
                 └───────────────┬─────────────────┘
                                 ▼
                            Terraform
                                 │
                 ┌───────────────┴────────────────┐
                 │                                │
            S3 Remote State                   AWS VPC
                                                     │
                                             Public Subnet
                                                     │
                           ┌─────────────────────────┼────────────────────┐
                           │                         │                    │
                    Internet Gateway          Route Table          Security Group
                           │                                              │
                           └──────────────────────┬───────────────────────┘
                                                  │
                                                 EC2
                                          Ubuntu 24.04 Server
                                                  │
                                             EC2 User Data
                                                  │
                           ┌──────────────────────┼──────────────────────┐
                           │                      │                      │
                     Install Git          Install Python          Install venv
                           │                      │                      │
                           └──────────────────────┼──────────────────────┘
                                                  │
                                           Clone ShipStack
                                                  │
                                          Install dependencies
                                                  │
                                              Gunicorn
                                                  │
                                             Flask API
                                                  │
                                               HTTP :80
```

---

## Core Components

| Component          | Technology            | Purpose                                            |
| ------------------ | --------------------- | -------------------------------------------------- |
| Application        | Python + Flask        | REST-style web service                             |
| Application Server | Gunicorn              | Production WSGI server                             |
| Testing            | pytest                | Automated application tests                        |
| CI/CD              | GitHub Actions        | Automated testing and infrastructure workflow      |
| IaC                | Terraform             | AWS infrastructure provisioning                    |
| Cloud              | AWS                   | Infrastructure and application hosting             |
| Compute            | EC2                   | Hosts the Flask application                        |
| Networking         | VPC                   | Isolated AWS network                               |
| State Management   | Amazon S3             | Remote Terraform state                             |
| State Locking      | S3 lockfile           | Prevents conflicting Terraform operations          |
| Authentication     | AWS IAM + GitHub OIDC | Short-lived AWS authentication from GitHub Actions |

---

## AWS Infrastructure

Terraform manages the following resources:

| Resource                | Purpose                                            |
| ----------------------- | -------------------------------------------------- |
| VPC                     | Isolated AWS network                               |
| Public Subnet           | Network segment for the application server         |
| Internet Gateway        | Internet connectivity                              |
| Route Table             | Routes public traffic through the Internet Gateway |
| Route Table Association | Associates the public subnet with the route table  |
| Security Group          | Controls network access                            |
| EC2 Instance            | Hosts the application                              |

The infrastructure is defined in:

```text
infrastructure/main.tf
```

Current EC2 configuration:

```text
AMI:        Ubuntu 24.04
Instance:   t3.micro
Region:     ap-south-1
Protocol:   HTTP
Port:       80
```

The security group exposes HTTP traffic on port 80. SSH is not publicly exposed.

---

## Terraform Remote State

ShipStack uses Amazon S3 for Terraform state:

```text
S3 Bucket
└── shipstack/
    └── terraform.tfstate
```

Terraform backend configuration:

```hcl
backend "s3" {
  bucket       = "shipstack-terraform-state"
  key          = "shipstack/terraform.tfstate"
  region       = "ap-south-1"
  use_lockfile = true
}
```

This prevents Terraform state from being tied to an individual developer machine or GitHub Actions runner.

The state backend is configured with S3-based locking using:

```hcl
use_lockfile = true
```

Terraform state is intentionally not committed to Git.

---

## Application

The application is a lightweight Flask API with three endpoints.

### `/`

Returns basic service information.

### `/health`

Health-check endpoint used to verify that the application is running.

Example:

```json
{
  "status": "healthy"
}
```

### `/info`

Returns application metadata including service name and version.

The application code is located at:

```text
app/app.py
```

---

## EC2 Bootstrap

The EC2 instance uses Terraform User Data to configure itself automatically during startup.

```text
EC2 starts
    │
    ▼
Update package lists
    │
    ▼
Install Python + pip + venv + Git
    │
    ▼
Clone ShipStack repository
    │
    ▼
Create Python virtual environment
    │
    ▼
Install application dependencies
    │
    ▼
Start Gunicorn
    │
    ▼
Bind Flask application to port 80
```

This removes the need to manually configure the server after provisioning.

The bootstrap process is defined directly in the Terraform EC2 resource.

---

## CI/CD Pipeline

ShipStack uses GitHub Actions for automated validation and infrastructure deployment.

### Continuous Integration

Every push to `main` and pull request targeting `main` runs the test pipeline.

```text
GitHub
   │
   ▼
GitHub Actions
   │
   ▼
Checkout repository
   │
   ▼
Set up Python 3.13
   │
   ▼
Install dependencies
   │
   ▼
Run pytest
```

---

## AWS OIDC Authentication

ShipStack does not store long-lived AWS access keys inside GitHub.

Instead, GitHub Actions uses **OpenID Connect (OIDC)** to authenticate to AWS.

```text
GitHub Actions
      │
      │ OIDC token
      ▼
AWS IAM OIDC Provider
      │
      ▼
ShipStack-GitHubActions Role
      │
      ▼
Temporary AWS credentials
```

The IAM trust policy restricts access to the ShipStack repository and the approved deployment context.

This reduces the need to manage permanent AWS credentials inside GitHub.

---

## Terraform CI/CD Workflow

The current deployment workflow is:

```text
Push / Manual Trigger
        │
        ▼
     Run Tests
        │
        ▼
   AWS OIDC Login
        │
        ▼
  Verify AWS Identity
        │
        ▼
   Terraform Init
        │
        ▼
 Terraform Validate
        │
        ▼
  Terraform Plan
        │
        ▼
 Upload Saved Plan
        │
        ▼
 Production Approval
        │
        ▼
 Terraform Apply
```

The workflow is defined in:

```text
.github/workflows/ci.yml
```

Terraform is pinned in CI to provide a consistent execution environment.

---

## Controlled Production Deployment

ShipStack separates **planning** from **applying infrastructure changes**.

A normal push can generate and upload a Terraform plan without automatically modifying AWS infrastructure.

Production deployment is triggered manually through GitHub Actions.

The `production` GitHub Environment requires approval before Terraform Apply can proceed.

```text
Push
  ↓
Test
  ↓
Terraform Plan
  ↓
Saved Terraform Plan
  ↓
Manual Deployment Trigger
  ↓
Production Approval
  ↓
Terraform Apply
```

This prevents an ordinary code push from automatically making infrastructure changes.

---

## Testing

The Flask application includes automated pytest coverage.

Run the tests locally with:

```bash
python -m pytest
```

The project currently contains three application tests.

GitHub Actions executes the same test suite before infrastructure planning.

---

## Repository Structure

```text
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
```

---

## Local Development

### Prerequisites

Install:

* Python 3
* Git
* Terraform
* AWS CLI

### Clone

```bash
git clone <repository-url>
cd ShipStack
```

### Install Python dependencies

```bash
python -m pip install -r app/requirements.txt
```

### Run tests

```bash
python -m pytest
```

### Run the application locally

```bash
python app/app.py
```

The Flask development server listens on:

```text
http://127.0.0.1:5000
```

---

## Terraform Commands

Initialize Terraform:

```bash
cd infrastructure
terraform init
```

Validate configuration:

```bash
terraform validate
```

Preview infrastructure changes:

```bash
terraform plan
```

Apply infrastructure locally:

```bash
terraform apply
```

Destroy infrastructure:

```bash
terraform destroy
```

> **Warning:** AWS resources can incur charges. Destroy resources when they are no longer required.

For normal project deployment, the GitHub Actions workflow is the preferred controlled deployment path.

---

## Security

ShipStack currently follows several security-oriented practices:

### No long-lived AWS credentials in GitHub

GitHub Actions uses AWS OIDC instead of storing permanent AWS access keys.

### Restricted IAM trust

The GitHub Actions IAM role is restricted to the ShipStack repository and approved deployment context.

### Remote state

Terraform state is stored remotely in S3 rather than committed to the repository.

### HTTP-only application exposure

The application currently exposes:

```text
HTTP → TCP 80 → Internet
```

SSH is not publicly exposed by the security group.

### No Terraform state in Git

Terraform state and local Terraform working files are excluded through `.gitignore`.

---

## Current Status

| Component                     | Status       |
| ----------------------------- | ------------ |
| Flask application             | ✅ Working    |
| Automated tests               | ✅ Passing    |
| GitHub Actions CI             | ✅ Working    |
| Terraform infrastructure      | ✅ Working    |
| AWS VPC networking            | ✅ Working    |
| EC2 deployment                | ✅ Working    |
| EC2 bootstrap                 | ✅ Working    |
| GitHub OIDC authentication    | ✅ Working    |
| S3 Terraform remote state     | ✅ Working    |
| Terraform state locking       | ✅ Configured |
| Terraform plan in CI          | ✅ Working    |
| Saved Terraform plan artifact | ✅ Working    |
| Production approval           | ✅ Configured |
| Controlled Terraform apply    | ✅ Working    |
| Live health endpoint          | ✅ Verified   |

---

## What This Project Demonstrates

ShipStack was built to demonstrate practical DevOps and cloud engineering concepts rather than simply launching a server.

### Infrastructure as Code

AWS infrastructure is defined declaratively using Terraform instead of being manually created.

### CI/CD

Application tests and infrastructure planning are executed automatically through GitHub Actions.

### Cloud Authentication

GitHub Actions authenticates to AWS through OIDC and IAM role assumption.

### Remote State Management

Terraform state is stored centrally in Amazon S3 with state locking.

### Reproducible Server Provisioning

EC2 configures itself through User Data instead of requiring manual server setup.

### Controlled Production Deployment

Infrastructure changes are planned first and only applied after explicit production approval.

---

## Project Validation

The deployed service was verified through the public EC2 endpoint.

The health endpoint returns:

```json
{
  "status": "healthy"
}
```

The infrastructure was also validated through Terraform:

```text
No changes. Your infrastructure matches the configuration.
```

This confirms that the declared Terraform configuration, remote state, and deployed AWS infrastructure are synchronized.

---

## Limitations

ShipStack is intentionally designed as a focused mini-major project rather than a full production platform.

Current limitations include:

* HTTP instead of HTTPS
* Direct public EC2 access
* Single EC2 instance
* No load balancer
* No Auto Scaling
* No centralized application logging
* No CloudWatch dashboards or alarms
* No Docker-based deployment

These are deliberate boundaries for the current version rather than hidden production capabilities.

---

## Future Improvements

Possible future iterations include:

* HTTPS/TLS with AWS Certificate Manager
* Domain-based access
* Docker containerization
* Application logging
* CloudWatch monitoring and alarms
* Application Load Balancer
* Auto Scaling
* Multi-environment Terraform configuration
* Separate staging and production infrastructure
* Automated rollback strategies
* More comprehensive application and infrastructure tests

---

## Key Learning Outcomes

Through ShipStack, the project covered:

```text
Python
Flask
pytest
Git
GitHub
GitHub Actions
CI/CD
Terraform
Infrastructure as Code
AWS IAM
GitHub OIDC
Amazon S3
Terraform Remote State
AWS VPC
Subnetting
Internet Gateway
Route Tables
Security Groups
EC2
Linux Server Provisioning
Gunicorn
Cloud Deployment
```

---

## License

This project is licensed under the MIT License.

See `LICENSE` for details.

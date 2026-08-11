# ShipStack

> **Infrastructure-as-Code deployment pipeline for a Python web service on AWS**

ShipStack is a deployment-focused project that provisions AWS infrastructure with Terraform and automatically deploys a Flask API to an EC2 instance.

The project demonstrates the complete path from application source code to a publicly accessible cloud service:

$$\text{Code} \longrightarrow \text{Tests} \longrightarrow \text{CI} \longrightarrow \text{Infrastructure} \longrightarrow \text{Server Provisioning} \longrightarrow \text{Application}$$

---

## 🚀 Live Deployment

* **Service:** ShipStack
* **Platform:** AWS EC2
* **Region:** `ap-south-1`

### Health Check
`GET /`

**Response:**
```json
{
  "message": "Application is running",
  "service": "ShipStack"
}
🎯 Why ShipStack?Deploying a Python application manually involves configuring a server, networking, security rules, dependencies, and the application runtime. ShipStack automates that process.Instead of manually creating infrastructure through the AWS Console, Terraform defines the infrastructure as code. When the EC2 instance starts, a bootstrap script installs the required software, retrieves the application from GitHub, installs dependencies, and starts the service with Gunicorn.The result is a repeatable, declarative deployment process rather than a fragile, manually configured server.🏗️ ArchitecturePlaintext                         GitHub
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
What is Provisioned?Terraform currently manages the following core AWS components (defined in infrastructure/main.tf):ResourcePurposeVPCIsolated AWS cloud networkPublic SubnetNetwork segment hosting the application serverInternet GatewayEnables inbound/outbound internet accessRoute TableDirects public subnet traffic to the Internet GatewayRoute AssociationBinds the subnet to the public routing tableSecurity GroupControls inbound/outbound firewalled network trafficEC2 InstanceUbuntu Linux server hosting the application stack🛠️ Application StackApplication: Python, Flask, GunicornTesting: pytestInfrastructure: Terraform, AWS (VPC, Subnet, IGW, Route Table, Security Group, EC2)Continuous Integration: GitHub Actions📁 Repository StructurePlaintextShipStack/
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
💻 Local DevelopmentPrerequisitesPython 3.xGitTerraformAWS CLI configured with valid credentials1. Clone & Set UpBashgit clone [https://github.com/modidiya10-maker/ShipStack.git](https://github.com/modidiya10-maker/ShipStack.git)
cd ShipStack
2. Install DependenciesBashpython -m pip install -r app/requirements.txt
3. Run TestsBashpython -m pytest
4. Run Application LocallyBashpython app/app.py
☁️ Infrastructure DeploymentTerraform manages the cloud lifecycle.Bash# Navigate to infrastructure directory
cd infrastructure

# Initialize provider plugins
terraform init

# Validate configuration syntax
terraform validate

# Preview changes before applying
terraform plan

# Provision resources on AWS
terraform apply
⚠️ Note: AWS resources incur charges. Run terraform destroy when finished to tear down resources.⚙️ Deployment AutomationThe EC2 instance uses AWS User Data during initial boot to automate server configuration:$$\text{EC2 Boots} \rightarrow \text{Install Python \& Git} \rightarrow \text{Clone ShipStack} \rightarrow \text{VirtualEnv Setup} \rightarrow \text{Install Requirements} \rightarrow \text{Launch Gunicorn (Port 80)}$$This eliminates the need for manual SSH access or post-provisioning server execution.🧪 CI Pipeline & TestingEvery commit pushed to the repository triggers a automated run via GitHub Actions (.github/workflows/ci.yml).PlaintextPush → GitHub Actions → Install Dependencies → Run pytest → Pass/Fail Status
Run tests manually anytime:Bashpython -m pytest
Expected Output: 3 passed🔒 SecurityNetwork Boundary: The Security Group restricts inbound traffic strictly to HTTP on TCP 80. SSH (TCP 22) is disabled to minimize attack surface.State & Secrets: Terraform state files (*.tfstate), cache folders, and local environment files are explicitly excluded via .gitignore.Credentials: No AWS access keys or secrets are stored in source code; deployments rely on local execution profiles and GitHub secrets.📊 Current StatusComponentStatusDeployment✅ FunctionalInfrastructure✅ Terraform-managedApplication✅ Running on AWS EC2CI Pipeline✅ ActiveTests✅ Passing🗺️ RoadmapShipStack is intentionally kept minimal to demonstrate core IaC concepts clearly while allowing space for future architectural expansion:[ ] HTTPS / TLS configuration via Let's Encrypt[ ] Domain routing with AWS Route 53[ ] Containerized runtime using Docker & Amazon ECR[ ] Remote Terraform state backend (AWS S3 + DynamoDB)[ ] Full CD pipeline to automatically trigger terraform apply on main branch merges[ ] Centralized logging and monitoring via Amazon CloudWatch[ ] High Availability using Application Load Balancers (ALB) and Auto Scaling Groups📜 LicenseDistributed under the MIT License. See LICENSE for more information.

# Hello World Node.js Application on AWS ECS/Fargate

This project demonstrates how to deploy a simple "Hello World" Node.js application to AWS ECS/Fargate using Terraform for Infrastructure as Code (IaC) and GitHub Actions for Continuous Deployment (CD). The application is accessible via an Application Load Balancer (ALB) on AWS.

## Prerequisites

Before you begin, ensure you have the following installed:

- [Node.js](https://nodejs.org/)
- [Docker](https://www.docker.com/)
- [Terraform](https://www.terraform.io/)
- [AWS CLI](https://aws.amazon.com/cli/)
- [GitHub account](https://github.com/)

## Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/your-github-username/hello-world-nodejs.git
cd hello-world-nodejs
```
### 2. Initialize Terraform:
```bash
terraform init
```
### 3. Review the Terraform execution plan:
```bash
terraform plan
```
### 4. Apply the Terraform configuration:
```bash
terraform apply
```
### 5. After deployment, access your application using the ALB DNS name or IP address.

## GitHub Actions Deployment
This project also includes GitHub Actions for automated deployment. The deployment workflow is triggered on pushes to the main branch. Check the .github/workflows/deploy.yml file for details.

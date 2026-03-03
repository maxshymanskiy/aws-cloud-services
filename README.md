# Cloud Native Course Management System

A serverless web application for managing courses and authors, built with a React frontend and an AWS backend using Lambda and DynamoDB. The infrastructure is fully provisioned using Terraform.

## Architecture

The system utilizes a cloud-native architecture designed for scalability and maintainability.

- **Frontend**: Single Page Application (SPA) built with React and Redux.
- **Backend**: Serverless architecture using AWS Lambda functions.
- **Database**: NoSQL data storage using Amazon DynamoDB.
- **Hosting**: React SPA served globally via Amazon CloudFront backed by an S3 bucket.
- **Infrastructure**: Infrastructure as Code (IaC) managed via Terraform.

## Repository Structure

- `react-app-frontend/`: Contains the source code for the user interface, state management, and API integration.
- `infra/`: Contains Terraform configuration files for provisioning AWS resources, including DynamoDB tables, IAM roles, Lambda functions, S3 bucket, and CloudFront distribution.

## Features

- **Course Management**: Create, read, update, and delete courses.
- **Author Management**: Retrieve author details.
- **Serverless Compute**: Backend logic executes on demand without managing servers.
- **Persistent Storage**: Data is stored reliably in DynamoDB tables.
- **Static Hosting**: Frontend is built and deployed to S3/CloudFront automatically on every `terraform apply`.

## Getting Started

### Deployment

All infrastructure and the frontend are provisioned with a single Terraform apply. See [`infra/terraform/README.md`](infra/terraform/README.md) for full details.

```bash
cd infra/terraform
terraform init -backend-config=backend.config
aws-vault exec <profile> --no-session -- terraform apply
```

After apply, Terraform prints the live URL.

### Local Frontend Development

```bash
cd react-app-frontend
npm install
npm start
```

See [`react-app-frontend/README.md`](react-app-frontend/README.md) for details.

## License

This project is licensed under the MIT License.

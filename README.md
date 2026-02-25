# Cloud Native Course Management System

A serverless web application for managing courses and authors, built with a React frontend and an AWS backend using Lambda and DynamoDB. The infrastructure is fully provisioned using Terraform.

## Architecture

The system utilizes a cloud-native architecture designed for scalability and maintainability.

- **Frontend**: Single Page Application (SPA) built with React and Redux.
- **Backend**: Serverless architecture using AWS Lambda functions.
- **Database**: NoSQL data storage using Amazon DynamoDB.
- **Infrastructure**: Infrastructure as Code (IaC) managed via Terraform.

## Repository Structure

- `react-app-frontend/`: Contains the source code for the user interface, state management, and API integration.
- `infra/`: Contains Terraform configuration files for provisioning AWS resources, including DynamoDB tables, IAM roles, and Lambda functions.

## Features

- **Course Management**: Create, read, update, and delete courses.
- **Author Management**: Retrieve author details.
- **Serverless Compute**: Backend logic executes on demand without managing servers.
- **Persistent Storage**: Data is stored reliably in DynamoDB tables.

## Getting Started

### Infrastructure Deployment

The storage and compute resources must be provisioned before running the application.

1. Navigate to the infrastructure directory:
   ```bash
   cd infra/terraform
   ```

2. Initialize Terraform:
   ```bash
   terraform init -backend-config=backend.config
   ```

3. Apply the configuration to create AWS resources:
   ```bash
   terraform apply
   ```

### Application Setup

The application consists of a frontend React app and a local Node.js server (mock API) for development.

1. **Start the Mock API Server**:

   Open a new terminal and navigate to the server directory:
   ```bash
   cd react-app-frontend/server
   ```

   Install dependencies:
   ```bash
   npm install
   ```

   Start the server (runs on port 4000):
   ```bash
   npm start
   ```

2. **Start the Frontend Application**:

   Open another terminal and navigate to the frontend directory:
   ```bash
   cd react-app-frontend
   ```

   Install dependencies:
   ```bash
   npm install
   ```

   Start the development server:
   ```bash
   npm start
   ```

## License

This project is licensed under the MIT License.

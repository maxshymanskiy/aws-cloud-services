# Infrastructure Deployment Guide

## Overview

This documentation outlines the standard procedures for managing infrastructure using Terraform and `aws-vault`. It covers environment authentication, resource bootstrapping, and deployment workflows.

## Prerequisites

- **[Terraform](https://www.terraform.io/downloads)**: Infrastructure-as-Code tool.
- **[tfswitch](https://tfswitch.warrensbox.com/)**: Command-line tool to switch between different versions of Terraform.
- **[AWS CLI](https://aws.amazon.com/cli/)**: Command-line interface for AWS services.
- **[aws-vault](https://github.com/99designs/aws-vault)**: Secure credential storage and session management for AWS.

### Installing tfswitch

> **Tip:** Use `tfswitch` to automatically select and install the required Terraform version for your project based on the configuration. This avoids version conflicts when working across multiple environments. 

**Linux:**
```bash
curl -L https://raw.githubusercontent.com/warrensbox/terraform-switcher/release/install.sh | bash
```
- Chooose `v1.14.5` version of Terraform


## 1. Authentication Configuration

We utilize `aws-vault` to securely manage AWS credentials and generate temporary session tokens. This eliminates the need to store plaintext credentials in configuration files.

### Setup

1.  **Installation**: Install `aws-vault` via your system's package manager.
2.  **Profile Configuration**: Add your AWS credentials to the local vault.

    ```bash
    aws-vault add <profile_name>
    ```

### Usage

Execute commands within an authenticated session using `exec`.

```bash
aws-vault exec <profile_name> -- <command>
```

## 2. Remote Backend Bootstrap

Before initializing Terraform, the remote state backend (S3 Bucket) and locking mechanism (DynamoDB Table) must be provisioned.

> **Warning:** Ensure the S3 bucket name is globally unique. If the bucket already exists, the creation command will fail.

### Provisioning Resources

Use the AWS CLI wrapped in `aws-vault` to create the required infrastructure.

1.  **Create S3 Bucket** (State Storage):

    ```bash
    aws-vault exec <profile_name> \
        -- aws s3api create-bucket <account-id>-terraform-tfstate \
        --region <region> \
        --create-bucket-configuration LocationConstraint=<region>
    ```

    *Note: Enable versioning regarding standard compliance.*

    ```bash
    aws-vault exec <profile_name> \
        -- aws s3api put-bucket-versioning \
        --bucket <unique-bucket-name> \
        --versioning-configuration Status=Enabled
    ```

2.  **Create DynamoDB Table** (State Locking):

    ```bash
    aws-vault exec <profile_name> \
        -- aws dynamodb create-table \
        --region <region> \
        --table-name terraform-tfstate-lock \
        --attribute-definitions AttributeName=LockID,AttributeType=S \
        --key-schema AttributeName=LockID,KeyType=HASH \
        --provisioned-throughput ReadCapacityUnits=1,WriteCapacityUnits=1
    ```

## 3. Configuration Management

This project utilizes the `cloudposse/terraform-null-label` module (configured via [context.tf](./context.tf)) to enforce consistent resource naming and tagging conventions.

### The Context File (`context.tf`)

Variables such as `namespace`, `stage`, `name`, and `attributes` are combined to generate resource IDs.
- **Namespace**: Organization or project name (e.g., `lpnu`).
- **Stage**: Deployment stage (e.g., `dev`, `prod`).
- **Name**: Specific component name (e.g., `lambda`, `dynamodb`).

Ensure all modules inherit this context to maintain uniformity across the infrastructure.

## 4. Terraform Execution

All Terraform operations should be executed within the `aws-vault` context to ensure proper authentication. Use `tfswitch` to select the appropriate Terraform version before running commands.

### Version Management

Select the required Terraform version defined in the configuration. If no version is specified, `tfswitch` allows you to select one interactively.

```bash
tfswitch
```

### The --no-session Flag

> **Warning:** When running Terraform, `aws-vault` attempts to create a temporary session STS token. Terraform execution can sometimes be long-running or require specific IAM roles that conflict with the temporary session wrapper.

> **Tip:** If you encounter errors related to token expiration or permissions while using the STS server, use the `--no-session` flag. This passes the master credentials directly to the process without generating a temporary session token.

**Usage:**

```bash
aws-vault exec <profile_name> --no-session -- terraform <command>
```

### Standard Commands

1.  **Initialize**:
    Configures the backend and downloads provider plugins. This setup uses a partial configuration where backend details are stored in `backend.config`.

    > **Tip:** Always initialize with the backend configuration file to ensure the state is stored correctly in S3 and execute all commands via `aws-vault`.

    ```bash
    terraform init -backend-config=backend.config
    ```

2.  **Plan**:
    Generates an execution plan showing pending changes.

    ```bash
    terraform plan
    ```

3.  **Apply**:
    Applies the changes to the infrastructure.

    ```bash
    terraform apply
    ```

## 5. Lambda Testing Payloads

Use the following JSON payloads to test Lambda functions directly via the AWS Console or using `aws lambda invoke`. These structures match the event body expected by the function handlers.

### Save Course

**Function**: `save-course`

**Input**:

```json
{
  "title": "Clean Architecture: Patterns, Practices, and Principles",
  "authorId": "matthew-renze",
  "length": "5:10",
  "category": "Software Architecture"
}
```

### Update Course

**Function**: `update-course`

**Path parameter**: `id` = `clean-architecture-patterns-practices-principles`

**Input**:

```json
{
  "title": "Clean Architecture: Patterns, Practices, and Principles (Updated)",
  "watchHref": "http://www.pluralsight.com/courses/clean-architecture-patterns-practices-principles",
  "authorId": "matthew-renze",
  "length": "5:15",
  "category": "Software Architecture"
}
```

### Delete Course

**Function**: `delete-course`

**Path parameter**: `id` = `clean-architecture-patterns-practices-principles`

**Input**: none

### Get Course

**Function**: `get-course`

**Path parameter**: `id` = `clean-architecture-patterns-practices-principles`

**Input**: none

## 6. API Gateway

The `api_gateway` module provisions an AWS REST API Gateway that exposes all Lambda functions over HTTP. It is wired up automatically from the root module using the invoke ARNs and function names produced by the `lambda_functions` module.

### Resource Structure

| Path | Methods |
|---|---|
| `/authors` | `GET` |
| `/courses` | `GET`, `POST` |
| `/courses/{id}` | `GET`, `PUT`, `DELETE` |

All resources also expose an `OPTIONS` method to support CORS preflight requests from the React frontend.

### CORS

CORS is handled via `MOCK` integrations on every `OPTIONS` method. The allowed origin is set to `*`. Each resource advertises only the methods it actually supports through the `Access-Control-Allow-Methods` response header.

### Deployment and Stage

The API is deployed to a stage named `v1`. A `triggers` block on the deployment resource computes a hash of all method and integration IDs, forcing a new deployment whenever any route changes.

> **Tip:** If you need to force a manual redeployment without changing any routes, `terraform taint` the `aws_api_gateway_deployment.this` resource and re-apply.

```bash
terraform taint module.api_gateway.aws_api_gateway_deployment.this
terraform apply
```

### Retrieving the Invoke URL

After a successful `terraform apply`, the base URL of the deployed stage is available as an output.

```bash
terraform output api_invoke_url
```

The returned URL has the form `https://<api-id>.execute-api.<region>.amazonaws.com/v1`. Append a resource path to call an endpoint directly.

## 7. S3 Frontend

The `s3-frontend` module provisions static hosting for the React SPA and automatically builds and deploys it as part of `terraform apply`.

### Build and Deploy

The `null_resource` provisioner runs automatically when:
- The API Gateway invoke URL changes (the `REACT_APP_API_URL` env var embedded at build time would differ)
- Any file under `react-app-frontend/src/` or `react-app-frontend/public/` changes

The build steps executed locally are:
```bash
npm ci --legacy-peer-deps
npm run build
aws s3 sync build/ s3://<bucket> --delete
aws cloudfront create-invalidation --distribution-id <id> --paths "/*"
```

### SPA Routing

CloudFront is configured with `custom_error_response` blocks for both 403 and 404 errors from S3, returning `index.html` with status 200. This is required so that hard refreshes and direct links to React Router paths (e.g. `/course/abc`) load the app instead of returning an S3 error page.

### Outputs

After a successful `terraform apply`:

```bash
terraform output cloudfront_url
```

Returns the HTTPS CloudFront URL where the app is accessible.

### Forcing a Redeploy

If you need to force a rebuild and sync without changing any source files:

```bash
aws-vault exec <profile> --no-session -- terraform apply -replace=module.s3_frontend.null_resource.build_and_deploy
```

## 8. Monitoring

The `monitoring` module sets up CloudWatch alarms and SNS email notifications to alert on Lambda errors and unexpected AWS billing charges.

### Alarms

| Alarm | Source | Threshold | Period |
|---|---|---|---|
| Per-function error alarm | CloudWatch Logs metric filter (pattern: `ERROR`) | ≥ 1 error | 30 seconds |
| Billing alarm | `AWS/Billing` — `EstimatedCharges` | ≥ `billing_threshold` USD | 6 hours |

Each Lambda function gets its own CloudWatch Log metric filter that counts log lines matching `ERROR`. A corresponding alarm fires when at least one such count is recorded within the evaluation period. All alarms route to a single SNS topic.

### SNS Notifications

A single SNS topic is shared by all alarms. One email subscription is created using the `alert_email` variable. After the first `terraform apply`, AWS sends a confirmation email to that address — the subscription must be confirmed before any notifications are delivered.

> **Tip:** To update the billing threshold or alert email without rebuilding other infrastructure, change the variable value and run `terraform apply` — only the affected CloudWatch/SNS resources will be modified.
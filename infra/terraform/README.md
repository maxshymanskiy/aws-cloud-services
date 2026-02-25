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
**Input**:

```json
{
  "id": "clean-architecture-patterns-practices-principles",
  "title": "Clean Architecture: Patterns, Practices, and Principles (Updated)",
  "watchHref": "http://www.pluralsight.com/courses/clean-architecture-patterns-practices-principles",
  "authorId": "matthew-renze",
  "length": "5:15",
  "category": "Software Architecture"
}
```

### Delete Course

**Function**: `delete-course`
**Input**:

```json
{
  "id": "clean-architecture-patterns-practices-principles"
}
```

### Get Course

**Function**: `get-course`
**Input**:

```json
{
  "id": "clean-architecture-patterns-practices-principles"
}
```
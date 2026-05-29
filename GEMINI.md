# EKS OpenTofu Demo Project

This project provisions a production-ready AWS EKS cluster using OpenTofu (an open-source fork of Terraform). It follows infrastructure-as-code (IaC) best practices, including modular design, remote state management, and OIDC-based CI/CD integration.

## Project Overview

- **Core Technologies:** OpenTofu, AWS, Kubernetes, Helm, Kubectl.
- **Architecture:** Multi-AZ VPC, EKS with managed node groups, KMS encryption, and External Secrets Operator (ESO).
- **Backend:** Remote state stored in AWS S3 with state locking via DynamoDB.
- **CI/CD:** GitHub Actions workflows with OIDC for secure AWS authentication.

## Directory Structure

- `bootstrap/`: Initial setup for the infrastructure, including the S3 bucket for remote state and GitHub OIDC roles.
- `envs/`: Environment-specific configurations (e.g., `test`). Each environment has its own state and variable values.
- `modules/`: Reusable OpenTofu modules:
    - `vpc/`: Custom VPC with multi-CIDR support, public/private subnets, and NAT Gateways.
    - `eks/`: EKS cluster setup, including:
        - `addons/`: EKS managed addons (e.g., EBS CSI).
        - `eso/`: External Secrets Operator installation and configuration.
        - `kms/`: Encryption keys for cluster secrets and state.
- `.github/workflows/`: Automation for plan, apply, and cleanup operations.

## Core Concepts

### VPC & Networking
The VPC module creates a segmented network with public subnets (for LBs and NAT) and private subnets (for EKS nodes). It supports secondary CIDR blocks for scalability.

### EKS Cluster
The EKS cluster is provisioned with managed node groups. It uses IAM OIDC providers for service account roles and EKS Access Entries for cluster-level RBAC.

### Remote State
Infrastructure state is managed remotely. Before deploying any environment, the `bootstrap` stack must be applied to create the necessary S3 bucket and DynamoDB table.

## Building and Running

### Prerequisites
- [OpenTofu](https://opentofu.org/docs/intro/install/) installed.
- AWS CLI configured with appropriate credentials.

### Initial Setup (Bootstrap)
```bash
cd bootstrap
tofu init
tofu plan
tofu apply
```

### Deploying an Environment (e.g., test)
```bash
cd envs/test
tofu init
tofu plan
tofu apply
```

## Development Conventions

### Linting and Formatting
This project uses `pre-commit` to ensure code quality. Hooks include:
- `tofu_fmt`: Automatically formats and indents `.tf` and `.tofu` files.
- `trailing-whitespace`, `end-of-file-fixer`
- `check-yaml`, `check-json`
- `editorconfig-checker`
- `tofu fmt` (implied/recommended)

Install pre-commit hooks:
```bash
pre-commit install
```

### Naming and Tagging
- Resources are tagged with `Environment`, `ManagedBy: opentofu`, and `Project`.
- Use `random_id` suffixes for resources that require global uniqueness (like EKS cluster names or S3 buckets).

## Key Workflows

### Provisioning a New Environment
1. Create a new directory under `envs/`.
2. Copy `main.tf`, `providers.tf`, `variables.tf`, etc., from `test`.
3. Update the `backend` configuration in `providers.tf` with a new `key`.
4. Configure `terraform.tfvars` for the new environment.

### Cluster Updates
- To update the EKS version, change `cluster_version` in the environment's variables and run `tofu apply`.
- Managed node groups will be updated according to the `update_config` strategy.

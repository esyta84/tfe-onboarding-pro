# Terraform Enterprise Onboarding Automation

This repository contains a comprehensive solution for automating the onboarding process for Terraform Enterprise (TFE). The solution enables automated provisioning of TFE organizations, teams, projects, workspaces, and variable sets based on organizational structure and deployment requirements.

## Solution Overview

The onboarding automation provides:
- Creation and management of TFE teams with distinct permission sets
- Project creation with environment segregation (Dev, Preprod, Prod)
- Workspace creation based on environment mappings
- Variable sets for different environments and configurations
- Team access controls and RBAC implementation
- Support for complex environment mapping
- Cost code assignment and budget management

## Repository Structure

```
tfe-onboarding/
├── modules/                      # Reusable Terraform modules
│   ├── tfe-organization/         # Organization management
│   ├── tfe-team/                 # Team and permission management
│   ├── tfe-project/              # Project creation and configuration
│   ├── tfe-workspace/            # Workspace provisioning
│   ├── tfe-variable-set/         # Variable set management
│   └── tfe-environment-mapping/  # Environment mapping logic
├── terraform/                    # Main Terraform implementation
│   ├── main.tf                   # Main entry point
│   ├── variables.tf              # Input variable definitions
│   ├── outputs.tf                # Output definitions
│   ├── providers.tf              # Provider configuration
│   └── backend.tf                # State management configuration
├── config/                       # Configuration files
│   ├── environments.yaml         # Environment mapping configuration
│   ├── teams.yaml                # Team configuration
│   └── applications.yaml         # Application configuration
├── pipelines/                    # Azure DevOps pipeline configuration
│   └── azure-pipelines.yml       # Main pipeline definition
└── docs/                         # Additional documentation
    ├── ONBOARDING.md             # Onboarding process documentation
    └── ARCHITECTURE.md           # Solution architecture documentation
```

## Environment Mapping

The solution supports complex environment mapping between:
- Domain environments (dev, preprod, prod)
- Logical environments mapped to each domain
- Target platforms (AWS, Azure, vSphere)
- Hardware types for vSphere (hw1/hw2)
- Datacenter allocations (dc1/dc2)

## Workspace Naming Convention

Workspaces follow the naming convention: `{app}-{domain environment}-{logical-environment}-{target platform}-snow`

## Requirements

- HashiCorp/tfe provider version 0.64 or later
- Terraform 1.0.0 or later
- Azure DevOps for pipeline execution

## Usage

Please refer to the [ONBOARDING.md](docs/ONBOARDING.md) document for detailed usage instructions.

## CI/CD Integration

The solution includes Azure DevOps pipeline configuration with:
- Automated deployment for dev domain
- Manual approval gates for preprod and prod domains
- Validation steps to ensure onboarding requests meet organizational standards

## License

This project is proprietary and confidential.
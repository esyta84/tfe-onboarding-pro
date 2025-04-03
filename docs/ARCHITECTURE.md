# TFE Onboarding Automation Architecture

This document describes the architecture and design decisions of the TFE onboarding automation solution.

## Overview

The TFE onboarding automation is a Terraform-based solution that uses HashiCorp's TFE provider to programmatically manage Terraform Enterprise resources. The solution follows a modular approach with clear separation of concerns to enable flexibility, scalability, and maintainability.

## System Architecture

The solution consists of the following components:

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Configuration  │     │     Terraform    │     │    Terraform    │
│  YAML Files     │────▶│   Modules        │────▶│    Enterprise   │
└─────────────────┘     └──────────────────┘     └─────────────────┘
        ▲                        ▲                       ▲
        │                        │                       │
        │                        │                       │
        ▼                        ▼                       ▼
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│  Azure DevOps   │     │   TFE API        │     │    Keycloak     │
│  Pipeline       │────▶│   (HashiCorp)    │────▶│    SAML IDP     │
└─────────────────┘     └──────────────────┘     └─────────────────┘
```

## Component Details

### 1. Terraform Modules

The solution employs a modular structure with the following core modules:

#### 1.1. Organization Module (`tfe-organization`)

Manages the TFE organization, including:
- Organization creation and configuration
- Organization-wide settings
- Organization membership management

#### 1.2. Team Module (`tfe-team`)

Handles the creation and management of teams, including:
- Team creation with specific visibility settings
- Organization-level permissions assignment
- SAML role mappings for team identity
- Team membership management
- Team token generation for CI/CD pipeline authentication

#### 1.3. Project Module (`tfe-project`)

Manages TFE projects and team access controls:
- Project creation and configuration
- Team access assignments with granular permissions
- RBAC implementation through team access policies

#### 1.4. Workspace Module (`tfe-workspace`)

Creates and configures workspaces, including:
- Workspace creation with appropriate settings
- Execution mode configuration (remote, local, agent)
- VCS integration setup
- Terraform version specification
- Working directory configuration
- Workspace variables management

#### 1.5. Variable Set Module (`tfe-variable-set`)

Handles variable sets management:
- Variable set creation
- Variable definitions with appropriate sensitivity settings
- Variable set attachment to workspaces and projects

#### 1.6. Environment Mapping Module (`tfe-environment-mapping`)

Implements the complex mapping logic between:
- Domain environments (dev, preprod, prod)
- Logical environments (dev, test, qa, uat, staging, prod)
- Target platforms (AWS, Azure, vSphere)
- Hardware and datacenter combinations for vSphere

### 2. Configuration Management

The solution uses YAML files for configuration management:

#### 2.1. Environment Configuration (`environments.yaml`)

Defines the mapping between domain environments, logical environments, and target platforms, including:
- Environment-specific settings (auto-apply, Terraform version)
- Platform configuration (AWS, Azure, vSphere)
- Hardware and datacenter allocations for vSphere
- VCS repository mappings

#### 2.2. Team Configuration (`teams.yaml`)

Defines the team structure and access policies, including:
- Team templates for different roles (owners, contributors, readers)
- Organization-level permissions
- Project access templates
- Workspace access templates

#### 2.3. Application Configuration (`applications.yaml`)

Defines the applications to be onboarded, including:
- Application metadata (name, cost code, budget)
- Allowed target platforms
- Hardware restrictions
- Team definitions and mappings

### 3. Pipeline Integration

The solution includes Azure DevOps pipeline configuration for automated deployment:

#### 3.1. Validation Stage

Performs initial validation of the Terraform code and configuration files:
- Terraform syntax validation
- YAML file validation
- Basic configuration integrity checks

#### 3.2. Planning Stage

Generates the execution plan for the specified environment:
- Initializes Terraform with appropriate backend configuration
- Creates a plan file with environment-specific variables
- Outputs the plan for review

#### 3.3. Application Stages

Applies the Terraform configuration with appropriate approvals:
- Dev environment: automated deployment
- Preprod environment: requires manual approval
- Prod environment: requires enhanced approval gates

## Design Decisions

### 1. Separation of Configuration and Implementation

The solution separates configuration (YAML files) from implementation (Terraform modules) to enable:
- Easier onboarding of new applications without code changes
- Configuration validation before deployment
- Version control of configuration files
- YAML-based configuration for simplicity and readability

### 2. Modular Structure

The modular approach enables:
- Clear separation of concerns
- Independent module development and testing
- Code reusability
- Easier maintenance and updates

### 3. Environment Mapping

The complex environment mapping logic is encapsulated in a dedicated module to:
- Handle complex relationships between different environment types
- Support special handling for vSphere environments
- Enable consistent workspace naming
- Support hardware and datacenter restrictions

### 4. RBAC Implementation

The solution implements role-based access control through:
- Team-based access management
- Granular permission templates
- Domain-specific project segregation
- Environment-specific access controls

### 5. Pipeline Integration

The Azure DevOps pipeline integration enables:
- Continuous integration and deployment
- Environment-specific deployment gates
- Configuration validation before deployment
- Phased rollout strategy (dev → preprod → prod)

## Security Considerations

The solution incorporates several security features:

1. **Sensitive Variables**: All credentials and sensitive data are marked as sensitive to prevent exposure
2. **Two-Factor Authentication**: Mandatory 2FA for organization collaborators
3. **SAML Integration**: Integration with Keycloak for identity management
4. **RBAC**: Granular role-based access controls
5. **Environment Separation**: Strict separation between environments to prevent cross-environment access
6. **Destroy Protection**: Controls to prevent accidental destruction of production resources
7. **Multi-Account Strategy**: Each application team uses dedicated AWS accounts and Azure subscriptions for each domain environment, providing strong isolation between applications and environments

## Multi-Account Cloud Architecture

The solution supports a multi-account architecture for both AWS and Azure:

### AWS Multi-Account Strategy

Each application team is assigned dedicated AWS accounts for each domain environment (dev, preprod, prod):

```
App1 ─┬─ Dev Account (123456789012) ─── app1-dev VPC, subnets, security groups
      ├─ Preprod Account (234567890123) ─── app1-preprod VPC, subnets, security groups
      └─ Prod Account (345678901234) ─── app1-prod VPC, subnets, security groups

App2 ─┬─ Dev Account (456789012345) ─── app2-dev VPC, subnets, security groups
      ├─ Preprod Account (567890123456) ─── app2-preprod VPC, subnets, security groups
      └─ Prod Account (678901234567) ─── app2-prod VPC, subnets, security groups
```

For each AWS account:
- Account-specific variables (account ID, region, VPC ID, subnet IDs, security group IDs) are stored in application/domain-specific variable sets
- Account-specific credentials are stored in separate sensitive variable sets
- All AWS resources for a specific application/domain are deployed to the appropriate account

### Azure Multi-Subscription Strategy

Similarly, each application team is assigned dedicated Azure subscriptions for each domain environment:

```
App1 ─┬─ Dev Subscription (11111111-...) ─── app1-dev-rg resource group, VNet, subnets
      ├─ Preprod Subscription (33333333-...) ─── app1-preprod-rg resource group, VNet, subnets
      └─ Prod Subscription (55555555-...) ─── app1-prod-rg resource group, VNet, subnets

App2 ─┬─ Dev Subscription (77777777-...) ─── app2-dev-rg resource group, VNet, subnets
      ├─ Preprod Subscription (99999999-...) ─── app2-preprod-rg resource group, VNet, subnets
      └─ Prod Subscription (bbbbbbbb-...) ─── app2-prod-rg resource group, VNet, subnets
```

For each Azure subscription:
- Subscription-specific variables (subscription ID, tenant ID, resource group, location, VNet, subnets) are stored in application/domain-specific variable sets
- Subscription-specific credentials are stored in separate sensitive variable sets
- All Azure resources for a specific application/domain are deployed to the appropriate subscription

### Benefits of the Multi-Account/Subscription Strategy

This approach provides several benefits:

1. **Strong Isolation**: Resources from different applications and domains are completely isolated from each other
2. **Granular Security**: Access control can be tailored to each account/subscription
3. **Simplified Cost Tracking**: Costs are naturally segregated by account/subscription
4. **Blast Radius Containment**: Issues in one account don't affect others
5. **Compliance**: Easier to maintain regulatory compliance with clear boundaries
6. **Independent Quotas**: Each account/subscription has its own service quotas and limits

### Implementation in Terraform Enterprise

The multi-account strategy is implemented in TFE through:

1. Application-specific configuration in YAML files with account/subscription details for each domain
2. Domain-specific variable sets containing account configuration
3. Separate credential variable sets for each application/domain combination
4. TFE's native support for multi-account AWS and multi-subscription Azure deployments

## Scalability and Performance

The solution is designed for scalability and performance:

1. **Modular Design**: Allows for independent scaling of components
2. **Configuration-Driven**: New applications can be added without code changes
3. **Phased Deployment**: Resources are created in phases to manage API rate limits
4. **Remote State**: Uses TFE's remote state management for improved performance
5. **Workspace Concurrency**: Supports concurrent operations in TFE workspaces
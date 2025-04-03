# Terraform Enterprise Onboarding Process

This document outlines the process for onboarding new applications to Terraform Enterprise (TFE) using the automation solution.

## Prerequisites

Before beginning the onboarding process, ensure the following prerequisites are met:

1. Keycloak SAML setup is completed with proper role mappings
2. TFE API token with admin privileges is available
3. VCS provider (Azure Devops) is configured in TFE with proper OAuth token
4. Required platform credentials (AWS, Azure, vSphere) are available
5. Application teams have provided AWS account IDs and Azure subscription details for each domain environment (dev, preprod, prod)

## Onboarding a New Application

The onboarding process consists of the following steps:

### 1. Gather Cloud Account Information

Before adding a new application to the configuration, gather the following information from the application team:

#### For AWS deployments:
- AWS account IDs for each domain (dev, preprod, prod)
- AWS region for each domain
- VPC ID, subnet IDs, and security group IDs for each domain
- AWS access key and secret key for each domain account

#### For Azure deployments:
- Azure subscription IDs for each domain (dev, preprod, prod)
- Azure tenant IDs for each domain
- Resource group, location, VNet and subnet information for each domain
- Azure client ID and client secret for each domain subscription

### 2. Prepare Application Configuration

Add the application configuration to the `config/applications.yaml` file:

```yaml
applications:
  # Add your new application here
  mynewapp:
    name: "mynewapp"
    allowed_platforms:
      - "aws"
      - "azure"
      - "vsphere-dev"
      - "vsphere-prod"
    cost_code: "CC-MYAPP-001"  # Required for cost tracking
    budget: "500000"           # Budget in USD
    hw_restrictions:
      - "hw1"                  # Optional: restrict to specific hardware types (for vSphere)
    teams:
      owners:
        sso_team_id: "mynewapp-owners"
        team_members: []
      contributors:
        sso_team_id: "mynewapp-contributors"
        team_members: []
      readers:
        sso_team_id: "mynewapp-readers"
        team_members: []
    cloud_accounts:
      aws:
        dev:
          account_id: "123456789012"
          account_name: "mynewapp-dev"
          region: "ap-southeast-2"
          vpc_id: "vpc-abc123"
          subnet_ids: ["subnet-123", "subnet-456"]
          security_group_ids: ["sg-123", "sg-456"]
        preprod:
          account_id: "234567890123"
          account_name: "mynewapp-preprod"
          region: "ap-southeast-2"
          vpc_id: "vpc-def456"
          subnet_ids: ["subnet-789", "subnet-012"]
          security_group_ids: ["sg-789", "sg-012"]
        prod:
          account_id: "345678901234"
          account_name: "mynewapp-prod"
          region: "ap-southeast-2"
          vpc_id: "vpc-ghi789"
          subnet_ids: ["subnet-345", "subnet-678"]
          security_group_ids: ["sg-345", "sg-678"]
      azure:
        dev:
          subscription_id: "11111111-1111-1111-1111-111111111111"
          tenant_id: "22222222-2222-2222-2222-222222222222"
          resource_group: "mynewapp-dev-rg"
          location: "australiaeast"
          vnet_name: "mynewapp-dev-vnet"
          subnet_names: ["mynewapp-dev-subnet1", "mynewapp-dev-subnet2"]
        preprod:
          # ... similar structure for preprod
        prod:
          # ... similar structure for prod
```

### 3. Create Teams in Keycloak

Create the application teams in Keycloak with the following SAML roles:
- `mynewapp-owners`
- `mynewapp-contributors`
- `mynewapp-readers`

Assign users to these teams in Keycloak as appropriate.

### 4. Run the Onboarding Pipeline

1. Run the Azure DevOps pipeline with the `dev` environment parameter to create the development resources.
2. Review the plan output to ensure it matches expectations.
3. After the dev environment is created and tested, proceed with preprod and prod environments sequentially.

### 5. Update Cloud Credentials

After the initial onboarding, update the application-specific credential variables in TFE for each domain:

1. Open the TFE UI and navigate to the newly created variable sets for the application:
   - `<app-name>-dev-aws-credentials`
   - `<app-name>-dev-azure-credentials`
   - Same for preprod and prod domains

2. Update the credential values with the actual AWS access keys and Azure client credentials provided by the application team.

### 6. Verify Onboarding

After the pipeline completes, verify the following:

1. The application projects are created in TFE (one for each environment: dev, preprod, prod)
2. The workspaces are created according to the environment and platform mappings
3. The teams are created and have the proper permissions
4. Variable sets are attached to the appropriate workspaces, including:
   - AWS account configurations specific to the application
   - Azure subscription configurations specific to the application
   - Application-specific credential variable sets
5. Team members can access their workspaces with the expected permissions

### 7. Retrieve Team API Tokens

API tokens are automatically generated for each team during creation. These tokens can be used by application teams in their CI/CD pipelines to interact with TFE:

1. After the onboarding process is complete, retrieve the team tokens from the Terraform output:
   ```
   terraform output -json team_tokens
   ```

2. Securely distribute the tokens to each team:
   - `owners` team token to the team's owners
   - `contributors` team token to the team's contributors (if needed)
   - `readers` team token for read-only access (if needed)

These tokens should be treated as sensitive credentials and securely stored in the application team's CI/CD system (e.g., Azure DevOps variable groups, GitHub secrets, etc.).

## Using Team Tokens in CI/CD Pipelines

Application teams can use their team tokens to authenticate with Terraform Enterprise in their CI/CD pipelines. Here's a basic example for Azure DevOps:

```yaml
# Azure DevOps pipeline example
trigger:
  - main

pool:
  vmImage: ubuntu-latest

variables:
  - group: tfe-credentials # Contains TFE_TOKEN secret variable

steps:
  - script: |
      cat > ~/.terraformrc << EOF
      credentials "app.terraform.io" {
        token = "$(TFE_TOKEN)"
      }
      EOF
      chmod 0600 ~/.terraformrc
    displayName: 'Configure Terraform credentials'

  - script: |
      terraform init
      terraform plan
    displayName: 'Terraform Plan'
    
  - script: |
      terraform apply -auto-approve
    displayName: 'Terraform Apply'
    condition: succeeded()
```

For GitHub Actions:

```yaml
name: Terraform

on:
  push:
    branches: [ main ]
  pull_request:
    branches: [ main ]

jobs:
  terraform:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Setup Terraform
      uses: hashicorp/setup-terraform@v1
      with:
        cli_config_credentials_token: ${{ secrets.TFE_TOKEN }}
        
    - name: Terraform Init
      run: terraform init
      
    - name: Terraform Plan
      run: terraform plan
      
    - name: Terraform Apply
      if: github.ref == 'refs/heads/main' && github.event_name == 'push'
      run: terraform apply -auto-approve
```

## Special Considerations

### Application-Specific Cloud Accounts

Each application uses its own AWS accounts and Azure subscriptions for different domains:

- AWS account IDs and configurations are stored in application-specific variable sets
- Azure subscription IDs and configurations are stored in application-specific variable sets
- Credentials for each account/subscription are stored in separate sensitive variable sets

### Hardware and Datacenter Restrictions

For vSphere deployments, hardware and datacenter restrictions are applied based on:
- The `hw_restrictions` configuration in the application
- The available datacenter/hardware combinations in the environment configuration

### Cost Codes and Budgets

Cost codes and budgets are set as workspace variables to enable cost tracking and management.

### Phased Deployment

The onboarding process follows a phased approach:
1. Dev environments first
2. Preprod environments with approval
3. Prod environments with enhanced approval gates

### Team Token Management

- Each team receives a unique API token at creation time
- Tokens are generated with no expiration by default
- For enhanced security, consider setting an expiration date for tokens using the `token_expired_at` variable
- When a token expires or needs to be rotated, use the `force_regenerate_token` variable to create a new token

## Onboarding Team Workflow

For the onboarding team, the typical workflow is:

1. Receive and validate onboarding request, including cloud account details for each domain
2. Update the applications configuration file with the new application details
3. Create the required teams in Keycloak (if using SAML)
4. Submit a pull request for review
5. After approval, run the pipeline for the dev environment
6. Update the cloud credentials in TFE using the UI
7. Validate the deployment
8. Distribute team tokens to the application team owners
9. Proceed with preprod and prod environments as needed

## Troubleshooting

### Common Issues

- **Permissions errors**: Ensure the TFE token has sufficient privileges
- **SAML issues**: Verify Keycloak team IDs match the configuration
- **Missing VCS repositories**: Ensure the referenced VCS repositories exist and are accessible
- **Variable set errors**: Check that variable sets are properly defined
- **Cloud account issues**: Verify that AWS account IDs and Azure subscription details are correct
- **Credential errors**: Ensure that access keys and client secrets are correctly configured
- **Token issues**: If a team token is compromised, use `force_regenerate_token = true` to create a new token

### Support Contacts

For assistance, contact the following:
- TFE Platform Team: `platform-team@example.com`
- Onboarding Team: `onboarding-team@example.com` 
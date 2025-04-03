# TFE Team Module

This module manages Terraform Enterprise teams and their API tokens.

## Features

- Team creation with customizable visibility settings
- Organization-level permissions assignment
- SAML role mappings for team identity
- Team membership management
- Team token generation for CI/CD pipeline authentication

## Usage

```hcl
module "app_owners_team" {
  source = "../modules/tfe-team"

  name         = "app-owners"
  organization = "your-organization"
  visibility   = "organization"  # or "secret"
  
  # Organization-level permissions
  organization_access = {
    manage_workspaces = true
    manage_projects   = true
  }
  
  # SAML integration (if enabled)
  sso_team_id  = "app-owners-saml-id"
  
  # Team members
  team_members = ["user1", "user2"]
  
  # Token management
  force_regenerate_token = false
  token_expired_at       = "2025-12-31T23:59:59Z"  # Optional: ISO 8601 format
}
```

## Inputs

| Name                  | Description                                               | Type     | Default | Required |
|-----------------------|-----------------------------------------------------------|----------|---------|----------|
| name                  | Name of the team                                          | string   | -       | yes      |
| organization          | Name of the organization                                  | string   | -       | yes      |
| visibility            | Visibility of the team (secret or organization)           | string   | "organization" | no |
| organization_access   | Organization access permissions                           | object   | see below | no     |
| sso_team_id           | SSO team ID for SAML integration                          | string   | null    | no       |
| team_members          | List of team member usernames                             | list(string) | [] | no       |
| force_regenerate_token | Whether to force regeneration of the team token          | bool     | false   | no       |
| token_expired_at      | Expiration date for the team token in RFC3339 format      | string   | null    | no       |

### Default Organization Access

```hcl
{
  manage_policies         = false
  manage_policy_overrides = false
  manage_workspaces       = false
  manage_vcs_settings     = false
  manage_providers        = false
  manage_modules          = false
  manage_run_tasks        = false
  manage_projects         = false
  manage_membership       = false
}
```

## Outputs

| Name               | Description                                 |
|--------------------|---------------------------------------------|
| id                 | The ID of the team                          |
| name               | The name of the team                        |
| organization_access| The organization access settings for the team|
| token              | The team's API token (sensitive)            |
| token_id           | The ID of the team token                    |

## Team Tokens

This module automatically generates an API token for each team. These tokens allow application teams to authenticate with TFE in their CI/CD pipelines without requiring personal user tokens.

- Each team receives a unique API token at creation time
- Tokens have the same access level as the team itself
- Tokens can have an optional expiration date set via `token_expired_at`
- Tokens can be regenerated using the `force_regenerate_token` option

### Token Security

- Tokens are treated as sensitive values and are only visible in the Terraform state
- It's recommended to use the `team_tokens` output from the main module to securely retrieve tokens
- Store tokens in a secure secret management system (e.g., Azure KeyVault, AWS Secrets Manager)
- Set an expiration date for sensitive environments
- Rotate tokens regularly using the `force_regenerate_token` option

## Example CI/CD Integration

```yaml
# Azure DevOps example
steps:
  - script: |
      cat > ~/.terraformrc << EOF
      credentials "app.terraform.io" {
        token = "$(TFE_TOKEN)"
      }
      EOF
      chmod 0600 ~/.terraformrc
    displayName: 'Configure Terraform credentials'
``` 
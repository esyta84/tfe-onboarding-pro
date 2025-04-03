/**
 * # TFE Team Module
 *
 * This module manages Terraform Enterprise teams and their access policies.
 */

terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.64.0"
    }
  }
}

# Create the team
resource "tfe_team" "team" {
  name         = var.name
  organization = var.organization
  visibility   = var.visibility
  organization_access {
    manage_policies         = var.organization_access.manage_policies
    manage_policy_overrides = var.organization_access.manage_policy_overrides
    manage_workspaces       = var.organization_access.manage_workspaces
    manage_vcs_settings     = var.organization_access.manage_vcs_settings
    manage_providers        = var.organization_access.manage_providers
    manage_modules          = var.organization_access.manage_modules
    manage_run_tasks        = var.organization_access.manage_run_tasks
    manage_projects         = var.organization_access.manage_projects
    manage_membership       = var.organization_access.manage_membership
  }
  sso_team_id = var.sso_team_id
}

# Generate a team token
resource "tfe_team_token" "token" {
  team_id = tfe_team.team.id
  
  # Set token expiration if specified
  force_regenerate = var.force_regenerate_token
  expired_at = var.token_expired_at
} 
/**
 * # TFE Organization Module
 *
 * This module manages Terraform Enterprise organizations.
 */

terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.64.0"
    }
  }
}

resource "tfe_organization" "org" {
  name  = var.name
  email = var.email

  session_timeout_minutes      = var.session_timeout_minutes
  session_remember_minutes     = var.session_remember_minutes
  collaborator_auth_policy     = var.collaborator_auth_policy
  cost_estimation_enabled      = var.cost_estimation_enabled
  owners_team_saml_role_id     = var.owners_team_saml_role_id
  send_passing_statuses_for_untriggered_speculative_plans = var.send_passing_statuses_for_untriggered_speculative_plans
  allow_force_delete_workspaces = var.allow_force_delete_workspaces
}

# SSO Configuration (if enabled)
resource "tfe_organization_membership" "members" {
  for_each = var.members

  organization = tfe_organization.org.name
  email        = each.value
} 
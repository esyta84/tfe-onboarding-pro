/**
 * # TFE Project Module
 *
 * This module manages Terraform Enterprise projects and their team access.
 */

terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.64.0"
    }
  }
}

# Create the project
resource "tfe_project" "project" {
  name         = var.name
  organization = var.organization
  description  = var.description
}

# Configure team access to the project
resource "tfe_team_project_access" "team_access" {
  for_each = var.team_access

  team_id    = each.value.team_id
  project_id = tfe_project.project.id
  access     = each.value.access
} 
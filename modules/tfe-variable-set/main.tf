/**
 * # TFE Variable Set Module
 *
 * This module manages Terraform Enterprise variable sets and their variables.
 */

terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.64.0"
    }
  }
}

# Create the variable set
resource "tfe_variable_set" "variable_set" {
  name         = var.name
  description  = var.description
  organization = var.organization
  global       = var.global
}

# Add variables to the variable set
resource "tfe_variable" "variables" {
  for_each = var.variables

  key             = each.key
  value           = each.value.value
  category        = each.value.category
  description     = each.value.description
  sensitive       = each.value.sensitive
  variable_set_id = tfe_variable_set.variable_set.id
  hcl             = each.value.hcl
}

# Connect the variable set to workspaces
resource "tfe_workspace_variable_set" "workspace_variable_sets" {
  for_each = toset(var.workspace_ids)

  workspace_id    = each.value
  variable_set_id = tfe_variable_set.variable_set.id
}

# Connect the variable set to projects
resource "tfe_project_variable_set" "project_variable_sets" {
  for_each = toset(var.project_ids)

  project_id      = each.value
  variable_set_id = tfe_variable_set.variable_set.id
} 
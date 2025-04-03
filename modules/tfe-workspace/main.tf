/**
 * # TFE Workspace Module
 *
 * This module manages Terraform Enterprise workspaces and their configurations.
 */

terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.64.0"
    }
  }
}

# Create the workspace
resource "tfe_workspace" "workspace" {
  name         = var.name
  organization = var.organization
  project_id   = var.project_id
  description  = var.description
  
  # Execution mode settings
  execution_mode = var.execution_mode
  agent_pool_id  = var.execution_mode == "agent" ? var.agent_pool_id : null
  
  # Run settings
  auto_apply            = var.auto_apply
  file_triggers_enabled = var.file_triggers_enabled
  queue_all_runs        = var.queue_all_runs
  global_remote_state   = var.global_remote_state
  remote_state_consumer_ids = var.remote_state_consumer_ids
  allow_destroy_plan    = var.allow_destroy_plan
  
  # VCS settings
  dynamic "vcs_repo" {
    for_each = var.vcs_repo != null ? [var.vcs_repo] : []
    content {
      identifier     = vcs_repo.value.identifier
      branch         = vcs_repo.value.branch
      oauth_token_id = vcs_repo.value.oauth_token_id
      ingress_submodules = vcs_repo.value.ingress_submodules
      tags_regex     = vcs_repo.value.tags_regex
    }
  }
  
  # Terraform settings
  terraform_version = var.terraform_version
  working_directory = var.working_directory

  # Tags
  tag_names = var.tag_names

  # Lifecycle
  lifecycle {
    ignore_changes = [
      vcs_repo,
      agent_pool_id
    ]
  }
}

# Add variables to the workspace
resource "tfe_variable" "variables" {
  for_each = var.variables

  workspace_id = tfe_workspace.workspace.id
  key          = each.key
  value        = each.value.value
  category     = each.value.category
  description  = each.value.description
  sensitive    = each.value.sensitive
}

# Connect workspace to variable sets
resource "tfe_workspace_variable_set" "variable_sets" {
  for_each = var.variable_set_ids

  workspace_id    = tfe_workspace.workspace.id
  variable_set_id = each.value
} 
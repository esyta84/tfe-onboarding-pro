/**
 * # TFE Environment Mapping Module
 *
 * This module handles the complex mapping between domain environments, logical environments,
 * target platforms, hardware types, and datacenter allocations.
 */

terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.64.0"
    }
  }
}

locals {
  # Convert domain environments mapping to a flattened list
  domain_environments = flatten([
    for domain_key, domain in var.domain_environments : [
      for logical_env in domain.logical_environments : {
        domain              = domain_key
        logical_environment = logical_env
        auto_apply          = domain.auto_apply
        terraform_version   = domain.terraform_version
      }
    ]
  ])

  # Convert target platforms to a flattened list
  target_platforms = flatten([
    for platform_key, platform in var.target_platforms : {
      key          = platform_key
      name         = platform.name
      is_vsphere   = platform.is_vsphere
      datacenter   = platform.datacenter
      hardware     = platform.hardware
      vcs_repo     = platform.vcs_repo
      variable_sets = platform.variable_sets
    }
  ])

  # Map app environments to target platforms
  app_env_platforms = flatten([
    for app_key, app in var.applications : [
      for domain_env in local.domain_environments : [
        for platform in local.target_platforms : {
          app_key             = app_key
          app_name            = app.name
          domain              = domain_env.domain
          logical_environment = domain_env.logical_environment
          platform_key        = platform.key
          platform_name       = platform.name
          is_vsphere          = platform.is_vsphere
          datacenter          = platform.datacenter
          hardware            = platform.hardware
          cost_code           = app.cost_code
          budget              = app.budget
          auto_apply          = domain_env.auto_apply
          terraform_version   = domain_env.terraform_version
          vcs_repo            = platform.vcs_repo
          variable_sets       = platform.variable_sets
          # Include only if the app has access to this platform
          enabled             = contains(app.allowed_platforms, platform.key)
        }
        if contains(app.allowed_platforms, platform.key)
      ]
    ]
  ])

  # Special handling for vSphere environments requiring multiple workspaces
  vsphere_workspaces = flatten([
    for env in local.app_env_platforms : env.is_vsphere ? [
      for dc in coalesce(env.datacenter, []) : [
        for hw in coalesce(env.hardware, []) : {
          app_key             = env.app_key
          app_name            = env.app_name
          domain              = env.domain
          logical_environment = env.logical_environment
          platform_key        = env.platform_key
          platform_name       = env.platform_name
          is_vsphere          = true
          datacenter          = dc
          hardware            = hw
          cost_code           = env.cost_code
          budget              = env.budget
          auto_apply          = env.auto_apply
          terraform_version   = env.terraform_version
          vcs_repo            = env.vcs_repo
          variable_sets       = env.variable_sets
          enabled             = env.enabled
          # Workspace name following naming convention
          workspace_name      = "${env.app_name}-${env.domain}-${env.logical_environment}-${env.platform_name}-${dc}-${hw}-snow"
        }
      ]
    ] : [{
      app_key             = env.app_key
      app_name            = env.app_name
      domain              = env.domain
      logical_environment = env.logical_environment
      platform_key        = env.platform_key
      platform_name       = env.platform_name
      is_vsphere          = false
      datacenter          = null
      hardware            = null
      cost_code           = env.cost_code
      budget              = env.budget
      auto_apply          = env.auto_apply
      terraform_version   = env.terraform_version
      vcs_repo            = env.vcs_repo
      variable_sets       = env.variable_sets
      enabled             = env.enabled
      # Workspace name following naming convention
      workspace_name      = "${env.app_name}-${env.domain}-${env.logical_environment}-${env.platform_name}-snow"
    }]
  ])

  # Final list of workspaces to create
  workspaces = [
    for workspace in local.vsphere_workspaces :
    workspace if workspace.enabled
  ]
} 
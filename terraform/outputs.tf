output "organization_id" {
  description = "The ID of the TFE organization"
  value       = module.organization.id
}

output "organization_name" {
  description = "The name of the TFE organization"
  value       = module.organization.name
}

output "teams" {
  description = "All teams created"
  value = {
    platform_admins = module.platform_admins_team.id
    onboarding_team = module.onboarding_team.id
    application_teams = {
      for app_key, team in module.application_teams : app_key => {
        owners      = team.id
        contributors = module.application_contributors[app_key].id
        readers     = module.application_readers[app_key].id
      }
    }
  }
}

output "team_tokens" {
  description = "API tokens for each team (sensitive)"
  sensitive   = true
  value = {
    platform_admins = module.platform_admins_team.token
    onboarding_team = module.onboarding_team.token
    application_teams = {
      for app_key, _ in module.application_teams : app_key => {
        owners       = module.application_teams[app_key].token
        contributors = module.application_contributors[app_key].token
        readers      = module.application_readers[app_key].token
      }
    }
  }
}

output "variable_sets" {
  description = "Variable sets created"
  value = {
    global                = module.global_variable_set.id
    templates = {
      aws_credentials     = module.aws_credentials_template.id
      azure_credentials   = module.azure_credentials_template.id
      vsphere_credentials = module.vsphere_credentials.id
    }
    app_specific = {
      aws_configs = {
        for key, config in module.app_account_configs : key => config.id
      }
      aws_credentials = {
        for key, creds in module.app_aws_credentials : key => creds.id
      }
      azure_configs = {
        for key, config in module.app_azure_configs : key => config.id
      }
      azure_credentials = {
        for key, creds in module.app_azure_credentials : key => creds.id
      }
    }
  }
}

output "projects" {
  description = "Projects created"
  value = {
    for key, project in module.application_projects : key => {
      id   = project.id
      name = project.name
    }
  }
}

output "workspaces" {
  description = "Workspaces created by the environment mapping"
  value = {
    for key, workspace in module.workspaces : key => {
      id   = workspace.id
      name = workspace.name
    }
  }
} 
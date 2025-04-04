/**
 * # TFE Onboarding Automation
 *
 * This is the main implementation for TFE onboarding automation.
 */

# Load configuration from YAML files
locals {
  # Load configuration files
  environments_config = yamldecode(file("${var.config_path}/environments.yaml"))
  teams_config        = yamldecode(file("${var.config_path}/teams.yaml"))
  applications_config = yamldecode(file("${var.config_path}/applications.yaml"))

  # Filter applications by deploy environment (for staged deployments)
  deploy_filter = var.deploy_environment == "dev" ? ["dev"] : (
    var.deploy_environment == "preprod" ? ["dev", "preprod"] : ["dev", "preprod", "prod"]
  )
}

# Create or reference the organization
module "organization" {
  source = "../modules/tfe-organization"

  name                       = var.organization_name
  email                      = var.organization_email
  collaborator_auth_policy   = "password"
  owners_team_saml_role_id   = var.keycloak_saml_enabled ? "owners" : null
  cost_estimation_enabled    = true
  allow_force_delete_workspaces = false
}

# Create base teams (platform admins and onboarding team)
module "platform_admins_team" {
  source = "../modules/tfe-team"

  name         = "platform-admins"
  organization = module.organization.name
  visibility   = local.teams_config.teams["platform-admins"].visibility
  organization_access = local.teams_config.teams["platform-admins"].organization_access
  sso_team_id  = var.keycloak_saml_enabled ? local.teams_config.teams["platform-admins"].sso_team_id : null
}

module "onboarding_team" {
  source = "../modules/tfe-team"

  name         = "onboarding-team"
  organization = module.organization.name
  visibility   = local.teams_config.teams["onboarding-team"].visibility
  organization_access = local.teams_config.teams["onboarding-team"].organization_access
  sso_team_id  = var.keycloak_saml_enabled ? local.teams_config.teams["onboarding-team"].sso_team_id : null
}

# Create global variable sets
module "global_variable_set" {
  source = "../modules/tfe-variable-set"

  name         = "global-vars"
  description  = "Global variables for all workspaces"
  organization = module.organization.name
  global       = true
  
  variables = {
    "TFE_WORKSPACE_NAME" = {
      value       = "This value is replaced with the actual workspace name"
      category    = "env"
      description = "The name of the workspace"
      sensitive   = false
    },
    "TFE_ORGANIZATION_NAME" = {
      value       = module.organization.name
      category    = "env"
      description = "The name of the organization"
      sensitive   = false
    }
  }
}

# Create template credential variable sets for each platform
module "aws_credentials_template" {
  source = "../modules/tfe-variable-set"

  name         = "aws-credentials-template"
  description  = "AWS credentials template (to be overridden by application-specific credentials)"
  organization = module.organization.name
  global       = false
  
  variables = {
    "AWS_ACCESS_KEY_ID" = {
      value       = "OVERRIDE_WITH_APP_SPECIFIC_KEY"
      category    = "env"
      description = "AWS access key (placeholder - to be overridden by application specific credentials)"
      sensitive   = true
    },
    "AWS_SECRET_ACCESS_KEY" = {
      value       = "OVERRIDE_WITH_APP_SPECIFIC_SECRET"
      category    = "env"
      description = "AWS secret key (placeholder - to be overridden by application specific credentials)"
      sensitive   = true
    }
  }
}

module "azure_credentials_template" {
  source = "../modules/tfe-variable-set"

  name         = "azure-credentials-template"
  description  = "Azure credentials template (to be overridden by application-specific credentials)"
  organization = module.organization.name
  global       = false
  
  variables = {
    "ARM_CLIENT_ID" = {
      value       = "OVERRIDE_WITH_APP_SPECIFIC_CLIENT_ID"
      category    = "env"
      description = "Azure client ID (placeholder - to be overridden by application specific credentials)"
      sensitive   = true
    },
    "ARM_CLIENT_SECRET" = {
      value       = "OVERRIDE_WITH_APP_SPECIFIC_CLIENT_SECRET"
      category    = "env"
      description = "Azure client secret (placeholder - to be overridden by application specific credentials)"
      sensitive   = true
    }
  }
}

module "vsphere_credentials" {
  source = "../modules/tfe-variable-set"

  name         = "vsphere-credentials"
  description  = "vSphere credentials for workspaces"
  organization = module.organization.name
  
  variables = {
    "VSPHERE_SERVER" = {
      value       = "vcenter.example.com"
      category    = "env"
      description = "vSphere server"
      sensitive   = false
    },
    "VSPHERE_USER" = {
      value       = "terraform-user"
      category    = "env"
      description = "vSphere username"
      sensitive   = true
    },
    "VSPHERE_PASSWORD" = {
      value       = "dummy-password"
      category    = "env"
      description = "vSphere password"
      sensitive   = true
    }
  }
}

# Application Teams
module "application_teams" {
  source   = "../modules/tfe-team"
  for_each = { 
    for app_key, app in local.applications_config.applications : app_key => app
    if contains(local.deploy_filter, var.deploy_environment)
  }

  # Owners team
  name         = "${each.value.name}-owners"
  organization = module.organization.name
  visibility   = local.teams_config.teams["app-team-owners-template"].visibility
  organization_access = local.teams_config.teams["app-team-owners-template"].organization_access
  sso_team_id  = var.keycloak_saml_enabled ? each.value.teams.owners.sso_team_id : null
}

module "application_contributors" {
  source   = "../modules/tfe-team"
  for_each = { 
    for app_key, app in local.applications_config.applications : app_key => app
    if contains(local.deploy_filter, var.deploy_environment)
  }

  # Contributors team
  name         = "${each.value.name}-contributors"
  organization = module.organization.name
  visibility   = local.teams_config.teams["app-team-contributors-template"].visibility
  organization_access = local.teams_config.teams["app-team-contributors-template"].organization_access
  sso_team_id  = var.keycloak_saml_enabled ? each.value.teams.contributors.sso_team_id : null
}

module "application_readers" {
  source   = "../modules/tfe-team"
  for_each = { 
    for app_key, app in local.applications_config.applications : app_key => app
    if contains(local.deploy_filter, var.deploy_environment)
  }

  # Readers team
  name         = "${each.value.name}-readers"
  organization = module.organization.name
  visibility   = local.teams_config.teams["app-team-readers-template"].visibility
  organization_access = local.teams_config.teams["app-team-readers-template"].organization_access
  sso_team_id  = var.keycloak_saml_enabled ? each.value.teams.readers.sso_team_id : null
}

# Projects (one per domain environment per application)
module "application_projects" {
  source   = "../modules/tfe-project"
  for_each = {
    for pair in setproduct(
      keys({ 
        for app_key, app in local.applications_config.applications : app_key => app
        if contains(local.deploy_filter, var.deploy_environment)
      }),
      ["dev", "preprod", "prod"]
    ) : "${pair[0]}-${pair[1]}" => {
      app_key = pair[0]
      domain  = pair[1]
    }
    if contains(local.deploy_filter, pair[1])
  }

  name         = "${local.applications_config.applications[each.value.app_key].name}-${each.value.domain}"
  organization = module.organization.name
  description  = "Project for ${local.applications_config.applications[each.value.app_key].name} application in ${each.value.domain} environment"

  # Team access configuration
  team_access = {
    platform_admins = {
      team_id = module.platform_admins_team.id
      access  = "admin"
    }
    onboarding_team = {
      team_id = module.onboarding_team.id
      access  = "maintain"
    }
    app_owners = {
      team_id = module.application_teams[each.value.app_key].id
      access  = "maintain"
    }
    app_contributors = {
      team_id = module.application_contributors[each.value.app_key].id
      access  = "write"
    }
    app_readers = {
      team_id = module.application_readers[each.value.app_key].id
      access  = "read"
    }
  }
}

# Environment mapping
module "environment_mapping" {
  source = "../modules/tfe-environment-mapping"

  domain_environments = local.environments_config.domain_environments
  target_platforms    = local.environments_config.target_platforms
  applications        = local.applications_config.applications
  organization        = module.organization.name
  vcs_enabled         = var.oauth_token_id != null
  
  project_ids = {
    for key, project in module.application_projects : key => project.id
  }
}

# Create workspaces based on environment mapping
module "workspaces" {
  source   = "../modules/tfe-workspace"
  for_each = {
    for workspace in module.environment_mapping.workspaces : 
      "${workspace.workspace_key}" => workspace
    if contains(local.deploy_filter, workspace.domain) && 
       contains(local.applications_config.applications[workspace.app_key].allowed_platforms, workspace.platform_key)
  }

  name         = each.value.workspace_name
  organization = module.organization.name
  project_id   = module.application_projects["${each.value.app_key}-${each.value.domain}"].id
  description  = "Workspace for ${each.value.app_name} in ${each.value.domain}/${each.value.logical_environment} environment on ${each.value.is_vsphere ? "DC ${each.value.datacenter} / HW ${each.value.hardware}" : each.value.platform_name} (SNOW)"
  
  execution_mode = var.oauth_token_id == null || var.oauth_token_id == "null" ? "local" : "remote"
  
  auto_apply            = each.value.auto_apply
  terraform_version     = each.value.terraform_version
  file_triggers_enabled = true
  queue_all_runs        = true
  allow_destroy_plan    = each.value.domain == "dev" ? true : false
  
  # VCS settings
  vcs_repo = each.value.vcs_repo != null && var.oauth_token_id != null && var.oauth_token_id != "null" ? {
    identifier     = each.value.vcs_repo.identifier
    branch         = each.value.vcs_repo.branch
    oauth_token_id = var.oauth_token_id
    ingress_submodules = coalesce(each.value.vcs_repo.ingress_submodules, false)
    tags_regex     = each.value.vcs_repo.tags_regex
  } : null
  
  # Apply cost code as a workspace variable
  variables = {
    "cost_code" = {
      value       = each.value.cost_code
      category    = "terraform"
      description = "Cost code for this application"
      sensitive   = false
    },
    "budget" = {
      value       = each.value.budget
      category    = "terraform"
      description = "Budget amount for this application"
      sensitive   = false
    },
    "environment" = {
      value       = each.value.logical_environment
      category    = "terraform"
      description = "Logical environment name"
      sensitive   = false
    },
    "domain" = {
      value       = each.value.domain
      category    = "terraform"
      description = "Domain environment name"
      sensitive   = false
    }
  }
  
  # Connect to variable sets
  variable_set_ids = merge(
    # Account-specific variable sets based on platform
    contains(["aws"], each.value.platform_key) && 
    lookup(module.app_aws_credentials, "${each.value.app_key}-${each.value.domain}", null) != null ? 
    {
      "aws-config" = module.app_account_configs["${each.value.app_key}-${each.value.domain}"].id,
      "aws-credentials" = module.app_aws_credentials["${each.value.app_key}-${each.value.domain}"].id
    } : {},
    
    contains(["azure"], each.value.platform_key) && 
    lookup(module.app_azure_credentials, "${each.value.app_key}-${each.value.domain}", null) != null ? 
    {
      "azure-config" = module.app_azure_configs["${each.value.app_key}-${each.value.domain}"].id,
      "azure-credentials" = module.app_azure_credentials["${each.value.app_key}-${each.value.domain}"].id
    } : {},
    
    # Platform-specific variable sets that aren't account-specific
    contains(["vsphere-dev", "vsphere-prod"], each.value.platform_key) ? {
      "vsphere-credentials" = module.vsphere_credentials.id
    } : {}
  )
  
  tag_names = [
    each.value.app_name,
    each.value.domain,
    each.value.logical_environment,
    each.value.is_vsphere ? each.value.platform_key : each.value.platform_name
  ]
}

# Create application-specific account configuration variable sets
module "app_account_configs" {
  source = "../modules/tfe-variable-set"
  for_each = {
    for pair in setproduct(
      keys({ 
        for app_key, app in local.applications_config.applications : app_key => app
        if contains(local.deploy_filter, var.deploy_environment) && 
           (lookup(app, "cloud_accounts", null) != null)
      }),
      ["dev", "preprod", "prod"]
    ) : "${pair[0]}-${pair[1]}" => {
      app_key = pair[0]
      domain  = pair[1]
    }
    if contains(local.deploy_filter, pair[1]) && 
       lookup(lookup(local.applications_config.applications[pair[0]], "cloud_accounts", {}), "aws", null) != null &&
       lookup(lookup(lookup(local.applications_config.applications[pair[0]], "cloud_accounts", {}), "aws", {}), pair[1], null) != null
  }

  name         = "${local.applications_config.applications[each.value.app_key].name}-${each.value.domain}-aws-config"
  description  = "AWS account configuration for ${local.applications_config.applications[each.value.app_key].name} in ${each.value.domain} environment"
  organization = module.organization.name
  application  = local.applications_config.applications[each.value.app_key].name
  domain       = each.value.domain
  
  # Create project-specific variable set for AWS account
  project_ids = {
    "${local.applications_config.applications[each.value.app_key].name}-${each.value.domain}" = module.application_projects["${each.value.app_key}-${each.value.domain}"].id
  }
  
  # Get the AWS account configs for this app and domain
  variables = {
    "AWS_ACCOUNT_ID" = {
      value       = local.applications_config.applications[each.value.app_key].cloud_accounts.aws[each.value.domain].account_id
      category    = "env"
      description = "AWS account ID for ${local.applications_config.applications[each.value.app_key].name} in ${each.value.domain}"
      sensitive   = false
    },
    "AWS_REGION" = {
      value       = local.applications_config.applications[each.value.app_key].cloud_accounts.aws[each.value.domain].region
      category    = "env"
      description = "AWS region for ${local.applications_config.applications[each.value.app_key].name} in ${each.value.domain}"
      sensitive   = false
    },
    "vpc_id" = {
      value       = local.applications_config.applications[each.value.app_key].cloud_accounts.aws[each.value.domain].vpc_id
      category    = "terraform"
      description = "VPC ID for ${local.applications_config.applications[each.value.app_key].name} in ${each.value.domain}"
      sensitive   = false
    },
    "subnet_ids" = {
      value       = jsonencode(local.applications_config.applications[each.value.app_key].cloud_accounts.aws[each.value.domain].subnet_ids)
      category    = "terraform"
      description = "Subnet IDs for ${local.applications_config.applications[each.value.app_key].name} in ${each.value.domain}"
      sensitive   = false
      hcl         = true
    },
    "security_group_ids" = {
      value       = jsonencode(local.applications_config.applications[each.value.app_key].cloud_accounts.aws[each.value.domain].security_group_ids)
      category    = "terraform"
      description = "Security group IDs for ${local.applications_config.applications[each.value.app_key].name} in ${each.value.domain}"
      sensitive   = false
      hcl         = true
    }
  }
}

# Create application-specific variable sets for Azure configurations
module "app_azure_configs" {
  source = "../modules/tfe-variable-set"
  for_each = {
    for pair in setproduct(
      keys({ 
        for app_key, app in local.applications_config.applications : app_key => app
        if contains(local.deploy_filter, var.deploy_environment) && 
           (lookup(app, "cloud_accounts", null) != null)
      }),
      ["dev", "preprod", "prod"]
    ) : "${pair[0]}-${pair[1]}" => {
      app_key = pair[0]
      domain  = pair[1]
    }
    if contains(local.deploy_filter, pair[1]) && 
       lookup(lookup(local.applications_config.applications[pair[0]], "cloud_accounts", {}), "azure", null) != null &&
       lookup(lookup(lookup(local.applications_config.applications[pair[0]], "cloud_accounts", {}), "azure", {}), pair[1], null) != null
  }

  name         = "${local.applications_config.applications[each.value.app_key].name}-${each.value.domain}-azure-config"
  description  = "Azure subscription configuration for ${local.applications_config.applications[each.value.app_key].name} in ${each.value.domain} environment"
  organization = module.organization.name
  application  = local.applications_config.applications[each.value.app_key].name
  domain       = each.value.domain
  
  # Create project-specific variable set for Azure subscription
  project_ids = {
    "${local.applications_config.applications[each.value.app_key].name}-${each.value.domain}" = module.application_projects["${each.value.app_key}-${each.value.domain}"].id
  }
  
  # Get the Azure subscription configs for this app and domain
  variables = {
    "ARM_SUBSCRIPTION_ID" = {
      value       = local.applications_config.applications[each.value.app_key].cloud_accounts.azure[each.value.domain].subscription_id
      category    = "env"
      description = "Azure subscription ID for ${local.applications_config.applications[each.value.app_key].name} in ${each.value.domain}"
      sensitive   = false
    },
    "ARM_TENANT_ID" = {
      value       = local.applications_config.applications[each.value.app_key].cloud_accounts.azure[each.value.domain].tenant_id
      category    = "env"
      description = "Azure tenant ID for ${local.applications_config.applications[each.value.app_key].name} in ${each.value.domain}"
      sensitive   = false
    },
    "resource_group" = {
      value       = local.applications_config.applications[each.value.app_key].cloud_accounts.azure[each.value.domain].resource_group
      category    = "terraform"
      description = "Azure resource group for ${local.applications_config.applications[each.value.app_key].name} in ${each.value.domain}"
      sensitive   = false
    },
    "location" = {
      value       = local.applications_config.applications[each.value.app_key].cloud_accounts.azure[each.value.domain].location
      category    = "terraform"
      description = "Azure location for ${local.applications_config.applications[each.value.app_key].name} in ${each.value.domain}"
      sensitive   = false
    },
    "vnet_name" = {
      value       = local.applications_config.applications[each.value.app_key].cloud_accounts.azure[each.value.domain].vnet_name
      category    = "terraform"
      description = "Azure VNet name for ${local.applications_config.applications[each.value.app_key].name} in ${each.value.domain}"
      sensitive   = false
    },
    "subnet_names" = {
      value       = jsonencode(local.applications_config.applications[each.value.app_key].cloud_accounts.azure[each.value.domain].subnet_names)
      category    = "terraform"
      description = "Azure subnet names for ${local.applications_config.applications[each.value.app_key].name} in ${each.value.domain}"
      sensitive   = false
      hcl         = true
    }
  }
}

# Create application-specific AWS credential variable sets
module "app_aws_credentials" {
  source = "../modules/tfe-variable-set"
  for_each = {
    for pair in setproduct(
      keys({ 
        for app_key, app in local.applications_config.applications : app_key => app
        if contains(local.deploy_filter, var.deploy_environment) && 
           (lookup(app, "cloud_accounts", null) != null)
      }),
      ["dev", "preprod", "prod"]
    ) : "${pair[0]}-${pair[1]}" => {
      app_key = pair[0]
      domain  = pair[1]
    }
    if contains(local.deploy_filter, pair[1]) && 
       lookup(lookup(local.applications_config.applications[pair[0]], "cloud_accounts", {}), "aws", null) != null &&
       lookup(lookup(lookup(local.applications_config.applications[pair[0]], "cloud_accounts", {}), "aws", {}), pair[1], null) != null
  }

  name         = "${local.applications_config.applications[each.value.app_key].name}-${each.value.domain}-aws-credentials"
  description  = "AWS credentials for ${local.applications_config.applications[each.value.app_key].name} in ${each.value.domain} environment"
  organization = module.organization.name
  application  = local.applications_config.applications[each.value.app_key].name
  domain       = each.value.domain
  
  # Create project-specific variable set for AWS credentials
  project_ids = {
    "${local.applications_config.applications[each.value.app_key].name}-${each.value.domain}" = module.application_projects["${each.value.app_key}-${each.value.domain}"].id
  }
  
  # Using placeholders - in real deployment, the onboarding team would retrieve actual credentials from the application team
  variables = {
    "AWS_ACCESS_KEY_ID" = {
      value       = "ACCESS_KEY_FOR_${upper(local.applications_config.applications[each.value.app_key].name)}_${upper(each.value.domain)}"
      category    = "env"
      description = "AWS access key for ${local.applications_config.applications[each.value.app_key].name} in ${each.value.domain}"
      sensitive   = true
    },
    "AWS_SECRET_ACCESS_KEY" = {
      value       = "SECRET_KEY_FOR_${upper(local.applications_config.applications[each.value.app_key].name)}_${upper(each.value.domain)}"
      category    = "env"
      description = "AWS secret key for ${local.applications_config.applications[each.value.app_key].name} in ${each.value.domain}"
      sensitive   = true
    }
  }
}

# Create application-specific Azure credential variable sets
module "app_azure_credentials" {
  source = "../modules/tfe-variable-set"
  for_each = {
    for pair in setproduct(
      keys({ 
        for app_key, app in local.applications_config.applications : app_key => app
        if contains(local.deploy_filter, var.deploy_environment) && 
           (lookup(app, "cloud_accounts", null) != null)
      }),
      ["dev", "preprod", "prod"]
    ) : "${pair[0]}-${pair[1]}" => {
      app_key = pair[0]
      domain  = pair[1]
    }
    if contains(local.deploy_filter, pair[1]) && 
       lookup(lookup(local.applications_config.applications[pair[0]], "cloud_accounts", {}), "azure", null) != null &&
       lookup(lookup(lookup(local.applications_config.applications[pair[0]], "cloud_accounts", {}), "azure", {}), pair[1], null) != null
  }

  name         = "${local.applications_config.applications[each.value.app_key].name}-${each.value.domain}-azure-credentials"
  description  = "Azure credentials for ${local.applications_config.applications[each.value.app_key].name} in ${each.value.domain} environment"
  organization = module.organization.name
  application  = local.applications_config.applications[each.value.app_key].name
  domain       = each.value.domain
  
  # Create project-specific variable set for Azure credentials
  project_ids = {
    "${local.applications_config.applications[each.value.app_key].name}-${each.value.domain}" = module.application_projects["${each.value.app_key}-${each.value.domain}"].id
  }
  
  # Using placeholders - in real deployment, the onboarding team would retrieve actual credentials from the application team
  variables = {
    "ARM_CLIENT_ID" = {
      value       = "CLIENT_ID_FOR_${upper(local.applications_config.applications[each.value.app_key].name)}_${upper(each.value.domain)}"
      category    = "env"
      description = "Azure client ID for ${local.applications_config.applications[each.value.app_key].name} in ${each.value.domain}"
      sensitive   = true
    },
    "ARM_CLIENT_SECRET" = {
      value       = "CLIENT_SECRET_FOR_${upper(local.applications_config.applications[each.value.app_key].name)}_${upper(each.value.domain)}"
      category    = "env"
      description = "Azure client secret for ${local.applications_config.applications[each.value.app_key].name} in ${each.value.domain}"
      sensitive   = true
    }
  }
} 
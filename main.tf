locals {
  deploy_filter = var.deploy_environment == "dev" ? ["dev"] : (
    var.deploy_environment == "preprod" ? ["dev", "preprod"] : ["dev", "preprod", "prod"]
  )
}

output "debug_vsphere_workspaces" {
  value = distinct([
    for workspace in module.environment_mapping.workspaces : 
      workspace.workspace_name
    if contains(["vsphere-dev", "vsphere-prod"], workspace.platform_key)
  ])
}

output "debug_workspace_keys" {
  value = {
    for workspace in module.environment_mapping.workspaces : 
      "${workspace.platform_key}-${workspace.workspace_key}" => {
        platform_key = workspace.platform_key
        workspace_key = workspace.workspace_key
        workspace_name = workspace.workspace_name
      }
  }
}

# Create workspaces based on environment mapping
module "workspaces" {
  source   = "../modules/tfe-workspace"
  for_each = {
    for workspace in module.environment_mapping.workspaces : 
      workspace.workspace_key => workspace
    if contains(local.deploy_filter, workspace.domain) && 
       contains(local.applications_config.applications[workspace.app_key].allowed_platforms, workspace.platform_key)
  }
}
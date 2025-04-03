output "id" {
  description = "The ID of the workspace"
  value       = tfe_workspace.workspace.id
}

output "name" {
  description = "The name of the workspace"
  value       = tfe_workspace.workspace.name
}

output "project_id" {
  description = "The ID of the project"
  value       = tfe_workspace.workspace.project_id
}

output "organization_name" {
  description = "The name of the organization"
  value       = tfe_workspace.workspace.organization
}

output "terraform_version" {
  description = "The version of Terraform used in the workspace"
  value       = tfe_workspace.workspace.terraform_version
}

output "execution_mode" {
  description = "The execution mode of the workspace"
  value       = tfe_workspace.workspace.execution_mode
}

output "variables" {
  description = "Map of variables defined in the workspace"
  value       = { for k, v in tfe_variable.variables : k => v.id }
} 
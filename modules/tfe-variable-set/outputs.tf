output "id" {
  description = "The ID of the variable set"
  value       = tfe_variable_set.variable_set.id
}

output "name" {
  description = "The name of the variable set"
  value       = tfe_variable_set.variable_set.name
}

output "organization" {
  description = "The organization name"
  value       = tfe_variable_set.variable_set.organization
}

output "global" {
  description = "Whether the variable set is global"
  value       = tfe_variable_set.variable_set.global
}

output "variables" {
  description = "Map of variables in the variable set"
  value       = { for k, v in tfe_variable.variables : k => v.id }
}

output "workspace_variable_sets" {
  description = "Map of workspace variable set connections"
  value       = { for k, v in tfe_workspace_variable_set.workspace_variable_sets : k => v.id }
}

output "project_variable_sets" {
  description = "Map of project variable set connections"
  value       = { for k, v in tfe_project_variable_set.project_variable_sets : k => v.id }
} 
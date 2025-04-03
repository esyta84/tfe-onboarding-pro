output "id" {
  description = "The ID of the project"
  value       = tfe_project.project.id
}

output "name" {
  description = "The name of the project"
  value       = tfe_project.project.name
}

output "organization_name" {
  description = "The name of the organization"
  value       = tfe_project.project.organization
}

output "team_access" {
  description = "Map of team access configurations for this project"
  value       = { for k, v in tfe_team_project_access.team_access : k => v.id }
  sensitive   = true
} 
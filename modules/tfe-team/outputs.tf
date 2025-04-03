output "id" {
  description = "The ID of the team"
  value       = tfe_team.team.id
}

output "name" {
  description = "The name of the team"
  value       = tfe_team.team.name
}

output "organization_access" {
  description = "The organization access settings for the team"
  value       = tfe_team.team.organization_access
}

output "token" {
  description = "The team's API token (sensitive)"
  value       = tfe_team_token.token.token
  sensitive   = true
}

output "token_id" {
  description = "The ID of the team token"
  value       = tfe_team_token.token.id
} 
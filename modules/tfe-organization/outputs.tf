output "id" {
  description = "The ID of the organization"
  value       = tfe_organization.org.id
}

output "name" {
  description = "The name of the organization"
  value       = tfe_organization.org.name
}

output "owners_team_id" {
  description = "The ID of the owners team"
  value       = tfe_organization.org.owners_team_id
}

output "members" {
  description = "The organization members"
  value       = { for k, v in tfe_organization_membership.members : k => v.id }
} 
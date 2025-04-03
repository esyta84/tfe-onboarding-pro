output "id" {
  description = "The ID of the organization"
  value       = tfe_organization.org.id
}

output "name" {
  description = "The name of the organization"
  value       = tfe_organization.org.name
}

output "members" {
  description = "The organization members"
  value       = { for k, v in tfe_organization_membership.members : k => v.id }
} 
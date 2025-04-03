output "workspaces" {
  description = "The list of workspaces to create"
  value       = local.workspaces
}

output "domain_environments" {
  description = "The flattened list of domain environments"
  value       = local.domain_environments
}

output "target_platforms" {
  description = "The flattened list of target platforms"
  value       = local.target_platforms
}

output "app_env_platforms" {
  description = "The mapped application environments to platforms"
  value       = local.app_env_platforms
}
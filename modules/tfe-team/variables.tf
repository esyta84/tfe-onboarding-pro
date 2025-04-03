variable "name" {
  description = "Name of the team"
  type        = string
}

variable "organization" {
  description = "Name of the organization"
  type        = string
}

variable "visibility" {
  description = "The visibility of the team (secret or organization)"
  type        = string
  default     = "organization"
  validation {
    condition     = contains(["secret", "organization"], var.visibility)
    error_message = "Visibility must be either 'secret' or 'organization'."
  }
}

variable "organization_access" {
  description = "Organization access permissions"
  type = object({
    manage_policies         = optional(bool, false)
    manage_policy_overrides = optional(bool, false)
    manage_workspaces       = optional(bool, false)
    manage_vcs_settings     = optional(bool, false)
    manage_providers        = optional(bool, false)
    manage_modules          = optional(bool, false)
    manage_run_tasks        = optional(bool, false)
    manage_projects         = optional(bool, false)
    manage_membership       = optional(bool, false)
  })
  default = {
    manage_policies         = false
    manage_policy_overrides = false
    manage_workspaces       = false
    manage_vcs_settings     = false
    manage_providers        = false
    manage_modules          = false
    manage_run_tasks        = false
    manage_projects         = false
    manage_membership       = false
  }
}

variable "sso_team_id" {
  description = "The SSO team ID (for SAML integration with Keycloak)"
  type        = string
  default     = null
}

variable "force_regenerate_token" {
  description = "Whether to force regeneration of the team token"
  type        = bool
  default     = false
}

variable "token_expired_at" {
  description = "The expiration date for the team token in RFC3339 format"
  type        = string
  default     = null
} 
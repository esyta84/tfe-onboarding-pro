variable "name" {
  description = "Name of the organization"
  type        = string
}

variable "email" {
  description = "Email address for the organization"
  type        = string
}

variable "admin_email" {
  description = "Admin email address for the organization"
  type        = string
  default     = null
}

variable "session_timeout_minutes" {
  description = "Session timeout in minutes"
  type        = number
  default     = 20160 # 14 days
}

variable "session_remember_minutes" {
  description = "Session remember time in minutes"
  type        = number
  default     = 20160 # 14 days
}

variable "collaborator_auth_policy" {
  description = "Authentication policy for collaborators (password, two_factor_mandatory, or anything else for default)"
  type        = string
  default     = "password"
  validation {
    condition     = contains(["password", "two_factor_mandatory"], var.collaborator_auth_policy)
    error_message = "Collaborator auth policy must be either 'password' or 'two_factor_mandatory'."
  }
}

variable "cost_estimation_enabled" {
  description = "Whether cost estimation is enabled for the organization"
  type        = bool
  default     = true
}

variable "owners_team_saml_role_id" {
  description = "The owners team SAML role ID"
  type        = string
  default     = null
}

variable "send_passing_statuses_for_untriggered_speculative_plans" {
  description = "Whether to send passing statuses for untriggered speculative plans"
  type        = bool
  default     = false
}

variable "allow_force_delete_workspaces" {
  description = "Whether to allow force-deleting workspaces with resources"
  type        = bool
  default     = false
}

variable "members" {
  description = "Map of members to add to the organization"
  type        = map(string)
  default     = {}
} 
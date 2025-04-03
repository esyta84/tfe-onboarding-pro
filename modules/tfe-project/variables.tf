variable "name" {
  description = "Name of the project"
  type        = string
}

variable "organization" {
  description = "Name of the organization"
  type        = string
}

variable "description" {
  description = "Description of the project"
  type        = string
  default     = ""
}

variable "team_access" {
  description = "Map of team IDs to their project access settings"
  type = map(object({
    access = string # read, write, maintain, admin
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.team_access : contains(["read", "write", "maintain", "admin"], v.access)
    ])
    error_message = "Access must be one of: read, write, maintain, admin."
  }
} 
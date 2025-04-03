variable "name" {
  description = "Name of the variable set"
  type        = string
}

variable "description" {
  description = "Description of the variable set"
  type        = string
  default     = ""
}

variable "organization" {
  description = "Name of the organization"
  type        = string
}

variable "global" {
  description = "Whether the variable set applies to all workspaces"
  type        = bool
  default     = false
}

variable "variables" {
  description = "Map of variables to add to the variable set"
  type = map(object({
    value       = string
    category    = string
    description = optional(string, "")
    sensitive   = optional(bool, false)
    hcl         = optional(bool, false)
  }))
  default = {}
  
  validation {
    condition = alltrue([
      for k, v in var.variables : contains(["terraform", "env"], v.category)
    ])
    error_message = "Variable category must be one of: terraform, env."
  }
}

variable "workspace_ids" {
  description = "List of workspace IDs to attach the variable set to"
  type        = list(string)
  default     = []
}

variable "project_ids" {
  description = "List of project IDs to attach the variable set to"
  type        = list(string)
  default     = []
}

variable "application" {
  description = "Application name for application-specific variable sets"
  type        = string
  default     = null
}

variable "domain" {
  description = "Domain environment (dev, preprod, prod) for domain-specific variable sets"
  type        = string
  default     = null
} 
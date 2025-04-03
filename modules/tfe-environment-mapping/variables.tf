variable "domain_environments" {
  description = "Map of domain environments (dev, preprod, prod) to their logical environments and settings"
  type = map(object({
    logical_environments = list(string)
    auto_apply           = bool
    terraform_version    = string
  }))
  default = {
    dev = {
      logical_environments = ["dev", "test", "qa"]
      auto_apply           = true
      terraform_version    = "1.5.7"
    },
    preprod = {
      logical_environments = ["uat", "staging"]
      auto_apply           = false
      terraform_version    = "1.5.7"
    },
    prod = {
      logical_environments = ["prod"]
      auto_apply           = false
      terraform_version    = "1.5.7"
    }
  }
}

variable "target_platforms" {
  description = "Map of target platforms (AWS, Azure, vSphere) to their settings"
  type = map(object({
    name         = string
    is_vsphere   = bool
    datacenter   = optional(list(string))  # Only relevant for vSphere
    hardware     = optional(list(string))  # Only relevant for vSphere
    vcs_repo     = optional(object({
      identifier          = string
      branch              = optional(string)
      oauth_token_id      = string
      ingress_submodules  = optional(bool, false)
      tags_regex          = optional(string)
    }))
    variable_sets = optional(list(string), [])
  }))
  default = {}
}

variable "applications" {
  description = "Map of applications with their settings and allowed platforms"
  type = map(object({
    name              = string
    allowed_platforms = list(string)  # List of platforms this app is allowed to deploy to
    cost_code         = string
    budget            = string
  }))
  default = {}
}

variable "organization" {
  description = "The organization name"
  type        = string
}

variable "project_ids" {
  description = "Map of application domain combinations to project IDs"
  type        = map(string)
  default     = {}
}

variable "vcs_enabled" {
  description = "Whether to use VCS integration for workspaces"
  type        = bool
  default     = true
} 
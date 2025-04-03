variable "name" {
  description = "Name of the workspace"
  type        = string
}

variable "organization" {
  description = "Name of the organization"
  type        = string
}

variable "project_id" {
  description = "ID of the project"
  type        = string
}

variable "description" {
  description = "Description of the workspace"
  type        = string
  default     = ""
}

variable "execution_mode" {
  description = "Execution mode of the workspace (remote, local, or agent)"
  type        = string
  default     = "remote"
  validation {
    condition     = contains(["remote", "local", "agent"], var.execution_mode)
    error_message = "Execution mode must be one of: remote, local, agent."
  }
}

variable "agent_pool_name" {
  description = "Name of the agent pool (required when execution_mode is 'agent')"
  type        = string
  default     = null
}

variable "auto_apply" {
  description = "Whether to automatically apply changes when a Terraform plan is successful"
  type        = bool
  default     = false
}

variable "file_triggers_enabled" {
  description = "Whether to filter runs based on the changed files in a VCS push"
  type        = bool
  default     = true
}

variable "queue_all_runs" {
  description = "Whether runs should be queued immediately after workspace creation"
  type        = bool
  default     = true
}

variable "global_remote_state" {
  description = "Whether the workspace should be accessible remotely from all other workspaces"
  type        = bool
  default     = false
}

variable "remote_state_consumer_ids" {
  description = "IDs of workspaces that can access the state from this workspace"
  type        = list(string)
  default     = []
}

variable "allow_destroy_plan" {
  description = "Whether to allow destroy plans"
  type        = bool
  default     = true
}

variable "terraform_version" {
  description = "The version of Terraform to use for this workspace"
  type        = string
  default     = null
}

variable "working_directory" {
  description = "Directory in the repo to use as the workspace working directory"
  type        = string
  default     = null
}

variable "vcs_repo" {
  description = "VCS repository settings"
  type = object({
    identifier          = string
    branch              = optional(string)
    oauth_token_id      = string
    ingress_submodules  = optional(bool, false)
    tags_regex          = optional(string)
  })
  default = null
}

variable "tag_names" {
  description = "List of tag names to apply to the workspace"
  type        = list(string)
  default     = []
}

variable "variables" {
  description = "Map of variables to add to the workspace"
  type = map(object({
    value        = string
    category     = string
    description  = optional(string, "")
    sensitive    = optional(bool, false)
  }))
  default = {}
  
  validation {
    condition = alltrue([
      for k, v in var.variables : contains(["terraform", "env"], v.category)
    ])
    error_message = "Variable category must be one of: terraform, env."
  }
}

variable "variable_set_ids" {
  description = "Map of variable set identifiers to their IDs to associate with the workspace"
  type        = map(string)
  default     = {}
} 
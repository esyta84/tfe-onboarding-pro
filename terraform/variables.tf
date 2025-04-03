variable "tfe_hostname" {
  description = "The hostname of the TFE instance"
  type        = string
  default     = "app.terraform.io"
}

variable "tfe_token" {
  description = "The API token for TFE"
  type        = string
  sensitive   = true
}

variable "organization_name" {
  description = "The name of the TFE organization"
  type        = string
}

variable "organization_email" {
  description = "The email address for the TFE organization"
  type        = string
}

variable "admin_email" {
  description = "The admin email address for the TFE organization"
  type        = string
  default     = null
}

variable "config_path" {
  description = "Path to the configuration files directory"
  type        = string
  default     = "../config"
}

variable "oauth_token_id" {
  description = "The OAuth token ID for VCS integration"
  type        = string
}

variable "deploy_environment" {
  description = "The environment to deploy (dev, preprod, prod)"
  type        = string
  default     = "dev"
  validation {
    condition     = contains(["dev", "preprod", "prod"], var.deploy_environment)
    error_message = "Deploy environment must be one of: dev, preprod, prod."
  }
}

variable "keycloak_saml_enabled" {
  description = "Whether Keycloak SAML integration is enabled"
  type        = bool
  default     = true
}

variable "agent_pool_id" {
  description = "Agent pool ID for agent execution mode workspaces"
  type        = string
  default     = null
} 
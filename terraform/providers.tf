terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.64.0"
    }
    
    # For YAML parsing
    local = {
      source  = "hashicorp/local"
      version = "~> 2.4.0"
    }
    
    # For additional data manipulation
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2.0"
    }
  }
  
  required_version = ">= 1.3.0"
}

provider "tfe" {
  hostname = var.tfe_hostname
  token    = var.tfe_token
} 
terraform {
  backend "remote" {
    organization = "your-organization-name"

    workspaces {
      name = "tfe-onboarding-automation"
    }
  }
} 
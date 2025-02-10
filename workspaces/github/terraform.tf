terraform {
  required_version = "1.10.5"

  backend "s3" {
    bucket                      = "homelab-terraform-state"
    key                         = "github/terraform.tfstate"
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    force_path_style            = true
  }

  required_providers {
    github = {
      source  = "integrations/github"
      version = "6.5.0"
    }
  }
}

provider "github" {
  owner = "ppat"
}

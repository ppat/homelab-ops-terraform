terraform {
  required_version = "1.6.6"

  backend "s3" {
    bucket                      = "homelab-terraform-state"
    key                         = "authentik/terraform.tfstate"
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    force_path_style            = true
  }
  required_providers {
    bitwarden = {
      source  = "maxlaverse/bitwarden"
      version = "0.13.0"
    }
    authentik = {
      source  = "goauthentik/authentik"
      version = "2024.12.1"
    }
  }
}

provider "bitwarden" {
  experimental {
    embedded_client = true
  }
}

provider "authentik" {
  url = "https://auth.homelab.${var.dns_zone}/"
}

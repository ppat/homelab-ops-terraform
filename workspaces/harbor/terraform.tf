terraform {
  required_version = "1.11.0"

  backend "s3" {
    bucket                      = "homelab-terraform-state"
    key                         = "harbor/terraform.tfstate"
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    force_path_style            = true
  }
  required_providers {
    # bitwarden = {
    #   source  = "maxlaverse/bitwarden"
    #   version = "0.13.0"
    # }
    harbor = {
      source  = "goharbor/harbor"
      version = "3.10.19"
    }
  }
}

provider "harbor" {
}

# provider "bitwarden" {
#   experimental {
#     embedded_client = true
#   }
# }

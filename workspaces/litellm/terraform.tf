terraform {
  required_version = "1.6.6"

  backend "s3" {
    bucket                      = "homelab-terraform-state"
    key                         = "litellm/terraform.tfstate"
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    force_path_style            = true
  }
  required_providers {
    bitwarden = {
      source  = "maxlaverse/bitwarden"
      version = "0.17.6"
    }
    litellm = {
      source  = "ncecere/litellm"
      version = "2.0.1"
    }
    # Used only by modules/litellm-virtual-key's object_permission REST seam — see the
    # comment at the top of that module's object-permission.tf for why it's needed and
    # how to remove it once ncecere/litellm gains native object_permission support.
    terracurl = {
      source  = "devops-rob/terracurl"
      version = "2.11.0"
    }
  }
}

provider "bitwarden" {
  experimental {
    embedded_client = true
  }
}

provider "litellm" {
}

provider "terracurl" {
}

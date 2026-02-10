terraform {
  required_version = "1.6.6"

  backend "s3" {
    bucket                      = "homelab-terraform-state"
    key                         = "minio-homelab/terraform.tfstate"
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    force_path_style            = true
  }
  required_providers {
    bitwarden = {
      source  = "maxlaverse/bitwarden"
      version = "0.17.3"
    }
    minio = {
      source  = "aminueza/minio"
      version = "3.13.2"
    }
  }
}

provider "bitwarden" {
  experimental {
    embedded_client = true
  }
}

provider "minio" {
  minio_server   = var.minio_homelab_endpoint
  minio_user     = var.minio_homelab_user
  minio_password = var.minio_homelab_password
  minio_ssl      = true
}

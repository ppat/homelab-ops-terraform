terraform {
  required_version = ">= 1.6"
  required_providers {
    bitwarden = {
      source  = "maxlaverse/bitwarden"
      version = ">= 0.13"
    }
    minio = {
      source  = "aminueza/minio"
      version = ">= 3.2"
    }
  }
}

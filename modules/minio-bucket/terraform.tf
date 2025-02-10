terraform {
  required_version = ">= 1.5"
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

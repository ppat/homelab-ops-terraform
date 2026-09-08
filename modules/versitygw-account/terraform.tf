terraform {
  required_version = ">= 1.6"
  required_providers {
    bitwarden = {
      source  = "maxlaverse/bitwarden"
      version = ">= 0.13"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6"
    }
  }
}

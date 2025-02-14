terraform {
  required_version = ">= 1.6"
  required_providers {
    authentik = {
      source  = "goauthentik/authentik"
      version = ">= 2024"
    }
  }
}

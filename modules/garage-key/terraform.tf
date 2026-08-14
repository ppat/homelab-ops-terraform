terraform {
  required_version = ">= 1.6"
  required_providers {
    bitwarden = {
      source  = "maxlaverse/bitwarden"
      version = ">= 0.13"
    }
    garage = {
      source  = "jkossis/garage"
      version = ">= 1.0"
    }
  }
}

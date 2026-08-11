terraform {
  required_version = ">= 1.6"
  required_providers {
    bitwarden = {
      source  = "maxlaverse/bitwarden"
      version = ">= 0.13"
    }
    litellm = {
      source  = "ncecere/litellm"
      version = ">= 2.0"
    }
    # Generic REST client used only by the object_permission seam in
    # object-permission.tf — see the comment at the top of that file for why.
    terracurl = {
      source  = "devops-rob/terracurl"
      version = ">= 2.0"
    }
  }
}

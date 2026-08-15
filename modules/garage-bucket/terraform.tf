terraform {
  required_version = ">= 1.6"
  required_providers {
    garage = {
      source  = "jkossis/garage"
      version = ">= 1.0"
    }
    # Generic REST client used only by the bucket-lifecycle seam (lifecycle.tf)
    # -- see the comment at the top of that file for why.
    terracurl = {
      source  = "devops-rob/terracurl"
      version = ">= 2.0"
    }
  }
}

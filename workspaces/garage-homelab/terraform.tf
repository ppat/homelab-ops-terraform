terraform {
  required_version = "1.6.6"

  # Deliberately still the MinIO-hosted bucket, not a Garage-hosted one --
  # backend-hosted state can't bootstrap into a bucket this same workspace is
  # what creates (see bucket-terraform-state.tf's comment). Migrating this
  # backend to Garage is a separate, later cutover, not part of provisioning
  # the bucket itself.
  backend "s3" {
    bucket                      = "homelab-terraform-state"
    key                         = "garage-homelab/terraform.tfstate"
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
    garage = {
      source  = "jkossis/garage"
      version = "1.0.5"
    }
    # Used only by modules/garage-bucket's lifecycle REST seam -- see the
    # comment at the top of that module's lifecycle.tf for why and how to
    # remove it once jkossis/garage gains native support.
    terracurl = {
      source  = "devops-rob/terracurl"
      version = "2.11.0"
    }
  }
}

provider "bitwarden" {
}

# No explicit endpoint/token args: the garage provider reads GARAGE_ENDPOINT /
# GARAGE_TOKEN from the environment (same convention as this repo's
# harbor/authentik/litellm providers). The garage_admin_endpoint /
# garage_admin_token variables below carry the SAME values into each module
# call's REST seams, which have no such implicit env var support.
#
# Reachability: the admin API (port 3903 on the `garage` Service, namespace
# garage) is reached through the `garage-admin` Ingress
# (infrastructure/subsystems/storage-core/garage/ingress-admin.yaml in
# homelab-ops-kubernetes-apps) -- no port-forward needed:
#   export GARAGE_ENDPOINT="https://garage-admin.${domain_name}"
#   export GARAGE_TOKEN="<admin-token>"        # Bitwarden key: cluster_homelab_garage_admin_token
#   export TF_VAR_garage_admin_endpoint="$GARAGE_ENDPOINT"
#   export TF_VAR_garage_admin_token="$GARAGE_TOKEN"
#
# That Ingress deliberately routes only the /v2 path, not /. Every call the
# garage provider and this workspace's terracurl REST seam
# (modules/garage-bucket's lifecycle.tf) make is a /v2/... endpoint, so this
# workspace never loses reachability to anything it needs. Widening
# the Ingress to `path: /` would also publish Garage's unauthenticated
# /metrics and /health there -- the /v2 scoping is what keeps those off this
# hostname, not an oversight to "fix" by broadening it.
provider "garage" {
}

provider "terracurl" {
}

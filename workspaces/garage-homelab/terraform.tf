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
    # Used only by modules/garage-bucket's lifecycle/web-alias REST seams --
    # see the comments at the top of that module's lifecycle.tf/alias.tf for
    # why and how to remove it once jkossis/garage gains native support.
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

# No explicit endpoint/token args: the garage provider reads GARAGE_ENDPOINT /
# GARAGE_TOKEN from the environment (same convention as this repo's
# harbor/authentik/litellm providers). The garage_admin_endpoint /
# garage_admin_token variables below carry the SAME values into each module
# call's REST seams, which have no such implicit env var support.
#
# Reachability: Garage's admin API (port 3903 on the `garage` Service, namespace
# garage) has no Ingress today -- only its S3 (3900) and website (3902) ports do
# (infrastructure/subsystems/storage-core/garage in homelab-ops-kubernetes-apps).
# That's a deliberate choice in that module (full bucket/key CRUD is a bigger
# thing to expose publicly than object storage itself), not an oversight here.
# Reach it via a port-forward before running Terraform:
#   kubectl --context <homelab context> -n garage port-forward svc/garage 3903:3903
#   export GARAGE_ENDPOINT="http://localhost:3903"
#   export GARAGE_TOKEN="<admin-token>"        # Bitwarden key: cluster_homelab_garage_admin_token
#   export TF_VAR_garage_admin_endpoint="$GARAGE_ENDPOINT"
#   export TF_VAR_garage_admin_token="$GARAGE_TOKEN"
provider "garage" {
}

provider "terracurl" {
}

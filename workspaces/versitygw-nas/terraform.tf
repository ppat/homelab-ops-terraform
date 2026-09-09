terraform {
  required_version = "1.6.6"

  backend "s3" {
    bucket                      = "homelab-terraform-state"
    key                         = "versitygw-nas/terraform.tfstate"
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
    random = {
      source  = "hashicorp/random"
      version = "3.9.0"
    }
  }
}

provider "bitwarden" {
  experimental {
    embedded_client = true
  }
}

# No provider reads the gateway: versitygw's admin API accepts only SigV4 and no provider
# signs it, so modules/versitygw-account drives it from a local-exec provisioner that reads
# three variables out of the ambient environment. They are needed at APPLY time only --
# `terraform validate` and `tflint` never run the script, which is why .ci.env's placeholder
# values are enough for CI and are not enough for anything else:
#
#   export VERSITYGW_ADMIN_ENDPOINT="https://versitygw-admin.${domain_name}"
#   export VERSITYGW_ADMIN_ACCESS_KEY="<root access key id>"   # Bitwarden key:
#                                                              # cluster_nas_versitygw_root_accesskeyid
#   export VERSITYGW_ADMIN_SECRET_KEY="<root secret key>"      # Bitwarden key:
#                                                              # cluster_nas_versitygw_root_secretkey
#   export VERSITYGW_ADMIN_REGION="us-east-1"                  # optional; this is the default,
#                                                              # and it must equal the region
#                                                              # every client signs with
#
# https, never http, and never a port-forward to the pod: `PATCH /list-users` returns every
# account's secret key in cleartext, so this traffic carries the whole store's credentials.
# The admin listener has its own hostname because the admin routes are top-level paths that
# would otherwise collide with S3 bucket paths; it is served by the object store module in
# ppat/homelab-ops-kubernetes-apps.
#
# The endpoint is not authenticated by anything but SigV4, so a wrong endpoint fails loudly
# (connection refused, or SignatureDoesNotMatch) rather than quietly writing somewhere else.
# .ci.env is written so that sourcing it cannot undo the exports above -- see its own note.

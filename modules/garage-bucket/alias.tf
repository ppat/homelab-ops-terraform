# ============================================================================
# SEAM -- second bucket alias (for public web access) via direct REST call.
# DELETE THIS FILE WHOLESALE once jkossis/garage's garage_bucket resource
# supports more than one global_alias (or a dedicated alias resource is added).
# ============================================================================
#
# The gap: jkossis/garage v1.0.5's garage_bucket resource manages exactly one
# global_alias (checked the schema in internal/provider/bucket_resource.go --
# Required, RequiresReplace, a single string; no repeated-block or list
# variant). Garage's Admin API itself supports a bucket having multiple global
# aliases via POST /v2/AddBucketAlias / RemoveBucketAlias (confirmed against
# the OpenAPI v2 spec's BucketAliasEnum schema: {bucketId, globalAlias}). The
# provider's own internal/client/client.go even has an AddBucketAlias Go
# function that calls this endpoint, but it is unused dead code -- no exposed
# resource calls it, and its request body shape ({id, alias}) does not match
# the real API schema ({bucketId, globalAlias}); do not copy it.
#
# Why a second alias at all: this bucket's real name (var.bucket_name) is what
# every consumer resolves the bucket by (modules/garage-key's own Bitwarden
# entries are keyed on the owning key's name, not this one -- keys and buckets
# have independent lifetimes, see that module for why). Garage's [s3_web]
# website endpoint resolves which bucket to serve purely
# from the Host header matching one of the bucket's global aliases -- and this
# estate's garage module
# (infrastructure/subsystems/storage-core/garage in homelab-ops-kubernetes-apps)
# only backs one such hostname today, so this bucket must ALSO carry that
# literal hostname as an alias to be reachable through it. Consequence: only
# one bucket across the whole Garage instance can set anonymous_read_hostname
# at a time, since they'd all need the identical alias value. That's a
# deliberate, current choice in the apps-repo module's own config, not a
# property of this seam or of Terraform, and not a Garage constraint either --
# see ppat/homelab-ops-kubernetes-apps#3652 for what produces it and what
# lifting it would take.
#
# That one-at-a-time constraint IS enforced -- but only at apply time, not
# plan time, and by Garage itself rather than by Terraform: POST
# /v2/AddBucketAlias rejects a second bucket claiming an alias already
# pointed at a different bucket with a 400 ("Alias ... already exists and
# points to different bucket: ...") -- confirmed against Garage v2.3.0's own
# source, src/model/helper/locked.rs's set_global_bucket_alias. So a second
# module call misconfigured with the same anonymous_read_hostname fails loud
# on `terraform apply`, it does not silently steal the alias from the first
# bucket -- but nothing here surfaces that at `terraform plan`.
resource "terracurl_request" "bucket_web_alias" {
  count = var.anonymous_read_hostname != null ? 1 : 0

  name   = "garage-bucket-${var.bucket_name}-web-alias"
  method = "POST"
  url    = "${trimsuffix(var.garage_admin_endpoint, "/")}/v2/AddBucketAlias"

  headers = {
    "Content-Type"  = "application/json"
    "Authorization" = "Bearer ${var.garage_admin_token}"
  }

  request_body = jsonencode({
    bucketId    = garage_bucket.bucket.id
    globalAlias = var.anonymous_read_hostname
  })

  response_codes = ["200"]
  skip_read      = true

  destroy_method = "POST"
  destroy_url    = "${trimsuffix(var.garage_admin_endpoint, "/")}/v2/RemoveBucketAlias"
  destroy_headers = {
    "Content-Type"  = "application/json"
    "Authorization" = "Bearer ${var.garage_admin_token}"
  }
  destroy_request_body = jsonencode({
    bucketId    = garage_bucket.bucket.id
    globalAlias = var.anonymous_read_hostname
  })
  destroy_response_codes = ["200"]
}

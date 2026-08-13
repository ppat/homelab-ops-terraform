# ============================================================================
# SEAM -- bucket lifecycle/expiration rules via direct REST call. DELETE THIS
# FILE WHOLESALE once jkossis/garage exposes lifecycle rules on garage_bucket
# (or an equivalent resource) natively.
# ============================================================================
#
# The gap: jkossis/garage v1.0.5's garage_bucket resource has no lifecycle
# argument (checked the provider's own source: internal/provider/bucket_resource.go
# only wires up global_alias/website_*/max_size/max_objects, and
# internal/client/client.go's UpdateBucketRequest struct has no lifecycleRules
# field). Garage's Admin API itself supports it fully and natively on the SAME
# endpoint the provider already calls for website/quota updates: POST
# /v2/UpdateBucket accepts a `lifecycleRules` array (confirmed against Garage
# v2.3.0's own source, src/api/admin/bucket.rs and
# src/api/common/xml/lifecycle.rs -- field names below are PascalCase XML tag
# names carried into the JSON body, because Garage's lifecycle config type is
# shared between the XML-based S3 API and the JSON admin API).
#
# This is a more reliable bridge than either competing provider's own lifecycle
# support: both Arsolitt/garagehq and d0ugal/garage implement it by PUTting
# S3-style lifecycle XML to `{bucket}?lifecycle` on the S3 port (3900) using the
# ADMIN bearer token as that request's Authorization header -- but Garage's S3
# API expects SigV4-signed requests, not bearer tokens, so that path looks
# likely to fail at apply time. This seam instead calls the real,
# natively-lifecycle-aware admin endpoint with the same bearer auth every other
# call in this module already uses successfully.
resource "terracurl_request" "bucket_lifecycle" {
  count = var.object_expiration_days != null ? 1 : 0

  name   = "garage-bucket-${var.bucket_name}-lifecycle"
  method = "POST"
  url    = "${trimsuffix(var.garage_admin_endpoint, "/")}/v2/UpdateBucket?id=${garage_bucket.bucket.id}"

  headers = {
    "Content-Type"  = "application/json"
    "Authorization" = "Bearer ${var.garage_admin_token}"
  }

  request_body = jsonencode({
    lifecycleRules = [
      {
        ID         = "expire-after-${var.object_expiration_days}-days"
        Status     = "Enabled"
        Expiration = { Days = var.object_expiration_days }
      }
    ]
  })

  response_codes = ["200"]

  # No read-based drift detection: the only source of truth this module
  # recognizes is its own config, same rationale as
  # modules/litellm-virtual-key/object-permission.tf.
  skip_read = true

  # A changed object_expiration_days replaces this resource (terracurl has no
  # in-place update -- changing request_body forces a destroy-then-create).
  # destroy_* below issues the clearing call FIRST, then create re-issues the
  # new value; both hit the same idempotent endpoint, so this is the correct
  # reconciliation, not a hazard.
  destroy_method = "POST"
  destroy_url    = "${trimsuffix(var.garage_admin_endpoint, "/")}/v2/UpdateBucket?id=${garage_bucket.bucket.id}"
  destroy_headers = {
    "Content-Type"  = "application/json"
    "Authorization" = "Bearer ${var.garage_admin_token}"
  }
  # An empty lifecycleRules array is what Garage's own handler treats as
  # "remove the lifecycle config entirely" (src/api/admin/bucket.rs:
  # `if lr.is_empty() { None }`) -- a real removal, not a no-op placeholder.
  destroy_request_body   = jsonencode({ lifecycleRules = [] })
  destroy_response_codes = ["200"]
}

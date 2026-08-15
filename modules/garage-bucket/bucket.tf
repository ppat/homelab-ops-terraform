resource "garage_bucket" "bucket" {
  global_alias = var.bucket_name

  # Garage has no S3 bucket-policy support, so anonymous public read only exists
  # via this website config. Reachability is automatic once enabled -- Garage's
  # [s3_web] endpoint resolves a bucket-name-prefixed subdomain of its
  # configured root_domain straight to this bucket's global_alias (no second
  # alias needed, see var.anonymous_read_enabled's description).
  website_enabled        = var.anonymous_read_enabled
  website_index_document = var.anonymous_read_enabled ? "index.html" : null
}

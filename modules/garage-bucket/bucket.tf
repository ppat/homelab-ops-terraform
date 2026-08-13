resource "garage_bucket" "bucket" {
  global_alias = var.bucket_name

  # Garage has no S3 bucket-policy support, so anonymous public read only exists
  # via this website config -- see var.anonymous_read_hostname's description for
  # the alias half of making a bucket actually reachable through it.
  website_enabled        = var.anonymous_read_hostname != null
  website_index_document = var.anonymous_read_hostname != null ? "index.html" : null
}

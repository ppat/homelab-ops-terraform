# The health canary writes, reads, lists and deletes one object here every run to prove the
# S3 path works end to end. A run deletes its own object, so the bucket stays empty.
module "health_canary" {
  source = "../../modules/garage-bucket"

  bucket_name           = "${local.bucket_prefix}-health-canary"
  garage_admin_endpoint = var.garage_admin_endpoint
  garage_admin_token    = var.garage_admin_token
}

module "health_canary_key" {
  source = "../../modules/garage-key"

  key_name = "healthcanary"
  buckets = {
    health_canary = {
      bucket_id = module.health_canary.bucket.id
      read      = true
      write     = true
    }
  }
  bitwarden_project_id = var.bitwarden_project_id
}

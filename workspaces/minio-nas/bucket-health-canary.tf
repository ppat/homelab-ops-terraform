# The health canary writes, reads, lists and deletes one object here every run to prove the
# S3 path works end to end. The one-day expiry only clears an object a failed DELETE left.
module "health_canary" {
  source = "../../modules/minio-bucket"

  bucket_name            = "${local.bucket_prefix}-health-canary"
  object_expiration_days = 1
  owner_username         = "health-canary"
  bitwarden_project_id   = var.bitwarden_project_id
}

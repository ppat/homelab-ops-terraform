module "cloudnativepg_backups" {
  source = "../../modules/minio-bucket"

  bucket_name            = "${local.bucket_prefix}-cloudnativepg-backups"
  object_expiration_days = 31
  owner_username         = "cloudnativepg"
  bitwarden_project_id   = var.bitwarden_project_id
}

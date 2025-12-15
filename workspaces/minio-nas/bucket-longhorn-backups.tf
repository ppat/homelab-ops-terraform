module "longhorn_backups" {
  source = "../../modules/minio-bucket"

  bucket_name            = "${local.bucket_prefix}-longhorn-backups"
  object_expiration_days = 31
  owner_username         = "longhorn"
  bitwarden_project_id   = var.bitwarden_project_id
}

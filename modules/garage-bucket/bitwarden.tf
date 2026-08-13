resource "bitwarden_secret" "bucket_owner_accesskey" {
  key        = "bucket_${replace(var.bucket_name, "/[^a-zA-Z0-9]/", "")}_accesskey"
  value      = garage_key.owner.id
  project_id = var.bitwarden_project_id
  note       = "${var.bucket_name} bucket's accesskey"
}

resource "bitwarden_secret" "bucket_owner_secretkey" {
  key        = "bucket_${replace(var.bucket_name, "/[^a-zA-Z0-9]/", "")}_secretkey"
  value      = garage_key.owner.secret_access_key
  project_id = var.bitwarden_project_id
  note       = "${var.bucket_name} bucket's secretkey"
}

# Adding a consumer is one entry here; nothing presumes how many there are.
module "accounts" {
  source = "../../modules/versitygw-account"

  accounts = {
    cloudnativepg = { bucket = "${local.bucket_prefix}-cloudnativepg-backups" }
    longhorn      = { bucket = "${local.bucket_prefix}-longhorn-backups" }

    # Owns no bucket. Exists so the WebUI can be used without the root key entering a
    # browser -- not because it is safe: an admin account can delete any bucket in the store.
    webui-admin = { role = "admin" }
  }

  bitwarden_project_id = var.bitwarden_project_id
}

module "authentik_media" {
  source = "../../modules/garage-bucket"

  bucket_name             = "${local.bucket_prefix}-authentik-media"
  owner_key_name          = "authentik"
  anonymous_read_hostname = var.garage_web_hostname
  bitwarden_project_id    = var.bitwarden_project_id
  garage_admin_endpoint   = var.garage_admin_endpoint
  garage_admin_token      = var.garage_admin_token
}

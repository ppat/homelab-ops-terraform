module "authentik_media" {
  source = "../../modules/garage-bucket"

  bucket_name            = "${local.bucket_prefix}-authentik-media"
  anonymous_read_enabled = true
  garage_admin_endpoint  = var.garage_admin_endpoint
  garage_admin_token     = var.garage_admin_token
}

module "authentik_media_key" {
  source = "../../modules/garage-key"

  key_name = "authentik"
  buckets = {
    authentik_media = {
      bucket_id = module.authentik_media.bucket.id
      read      = true
      write     = true
    }
  }
  bitwarden_project_id = var.bitwarden_project_id
}

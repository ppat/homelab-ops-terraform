module "loki_ruler" {
  source = "../../modules/garage-bucket"

  bucket_name           = "${local.bucket_prefix}-loki-ruler"
  owner_key_name        = "loki"
  bitwarden_project_id  = var.bitwarden_project_id
  garage_admin_endpoint = var.garage_admin_endpoint
  garage_admin_token    = var.garage_admin_token
}

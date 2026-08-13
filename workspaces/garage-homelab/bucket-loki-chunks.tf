# No object_expiration_days here: Loki's chunk retention is presumably enforced
# by Loki's own compactor (retention_period in its config), not S3/Garage
# lifecycle rules -- this workspace doesn't have visibility into that config to
# assert a matching number, and the MinIO original of this bucket was never
# under Terraform either (nothing to mirror). Revisit if Loki's compactor
# retention ever needs a bucket-side backstop.
module "loki_chunks" {
  source = "../../modules/garage-bucket"

  bucket_name           = "${local.bucket_prefix}-loki-chunks"
  owner_key_name        = "loki"
  bitwarden_project_id  = var.bitwarden_project_id
  garage_admin_endpoint = var.garage_admin_endpoint
  garage_admin_token    = var.garage_admin_token
}

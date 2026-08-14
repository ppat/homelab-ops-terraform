# No object_expiration_days on loki_chunks: Loki's chunk retention is presumably
# enforced by Loki's own compactor (retention_period in its config), not S3/Garage
# lifecycle rules -- this workspace doesn't have visibility into that config to
# assert a matching number, and the MinIO original of this bucket was never
# under Terraform either (nothing to mirror). Revisit if Loki's compactor
# retention ever needs a bucket-side backstop.
module "loki_chunks" {
  source = "../../modules/garage-bucket"

  bucket_name           = "${local.bucket_prefix}-loki-chunks"
  garage_admin_endpoint = var.garage_admin_endpoint
  garage_admin_token    = var.garage_admin_token
}

# key_name is "loki", not "loki_chunks" like this file/module's own name and
# unlike bucket-authentik-media.tf/bucket-terraform-state.tf's matching
# key_name/module-name pairs -- don't "fix" that to match. This key predates
# ppat/homelab-ops-terraform#294's key/permission/Bitwarden refactor, when it
# was also granted on the now-deleted homelab-loki-ruler bucket (see git
# history/moved.tf); it already exists in Garage under this exact name and
# backs Loki's live S3 credential today. key_name carries RequiresReplace
# (modules/garage-key/variables.tf) -- renaming it here would destroy and
# recreate that credential, not just a Terraform address.
module "loki_key" {
  source = "../../modules/garage-key"

  key_name = "loki"
  buckets = {
    loki_chunks = {
      bucket_id = module.loki_chunks.bucket.id
      read      = true
      write     = true
    }
  }
  bitwarden_project_id = var.bitwarden_project_id
}

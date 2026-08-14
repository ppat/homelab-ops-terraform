# ============================================================================
# TEMPORARY -- migration-only credential. DELETE THIS FILE WHOLESALE (and
# `terraform apply`) once the MinIO-to-Garage bucket migration is complete
# for all three buckets below (clusters#910's runbook, OPERATIONS.md
# "Runbook: migrate MinIO buckets to Garage"). Leaving it in place afterward
# is exactly the kind of standing broad-write privilege this project already
# rejected once, in dropping the Garage operator over its own cluster-wide
# Secret access -- a migration credential that outlives its migration is the
# same mistake in miniature.
# ============================================================================
#
# Lives at the workspace level, not inside modules/garage-bucket: it spans
# all three buckets below rather than belonging to any one of them, and the
# module's own garage_bucket_permission.owner is the wrong shape for this
# anyway (owner, not read+write; one bucket, not three).
#
# read+write, never owner -- same reasoning as modules/garage-bucket/key.tf's
# owner permission, checked against what clusters#910's scripts actually do
# rather than assumed: verify-bucket.sh reads back what it wrote (`rclone
# size`/`lsf`/`check` against the Garage destination -- LIST + HEAD/ETag
# comparisons, all read-permission operations) and preflight-canary.sh
# round-trips a throwaway object (`rcat`/`cat`/`deletefile` -- write already
# covers object delete in Garage's model, see key.tf). Nothing in
# clusters#910 ever touches a bucket's own configuration (website access,
# alias, deletion) -- the one thing `owner` grants beyond `read`+`write` --
# so `owner` here would be a wider grant than any script can even exercise.
resource "garage_key" "migration" {
  name = "minio-garage-migration"
}

resource "garage_bucket_permission" "migration_authentik_media" {
  bucket_id     = module.authentik_media.bucket.id
  access_key_id = garage_key.migration.id
  read          = true
  write         = true
}

resource "garage_bucket_permission" "migration_loki_chunks" {
  bucket_id     = module.loki_chunks.bucket.id
  access_key_id = garage_key.migration.id
  read          = true
  write         = true
}

resource "garage_bucket_permission" "migration_terraform_state" {
  bucket_id     = module.terraform_state.bucket.id
  access_key_id = garage_key.migration.id
  read          = true
  write         = true
}

# Bitwarden entry names are the owner's own, created by hand ahead of this
# PR (cluster_homelab_garage_migration_accesskeyid/_secretkey) -- a
# deliberate departure from modules/garage-bucket/bitwarden.tf's usual
# bucket_garage_<name>_accesskey/_secretkey convention, since this key isn't
# scoped to one bucket and the owner named it first. clusters#910's migration
# Job envsubsts GARAGE_ACCESS_KEY/GARAGE_SECRET_KEY from these two entries.
#
# First-apply note: Garage, not Bitwarden, mints the key ID/secret (see
# garage_key.migration above), so whatever the owner originally typed into
# these two entries is not a working credential -- they can only ever have
# been placeholders reserving the name. `bitwarden_secret` creates a new
# entry by ID; it does not adopt an existing entry by matching key name. So
# applying this against an already-populated project produces a SECOND
# entry with the same key, not an overwrite. Before the first `terraform
# apply` here: either delete the two hand-created placeholder entries in
# Bitwarden first, or `terraform import` them into these two resource
# addresses using their real Bitwarden secret IDs. Do this once, up front --
# Terraform has no way to detect or warn about the collision on its own.
resource "bitwarden_secret" "migration_accesskeyid" {
  key        = "cluster_homelab_garage_migration_accesskeyid"
  value      = garage_key.migration.id
  project_id = var.bitwarden_project_id
  note       = "MinIO->Garage migration key's access key ID -- read+write on homelab-loki-chunks, homelab-authentik-media, homelab-terraform-state. Temporary: retire per this file's own top-of-file comment once the migration is done."
}

resource "bitwarden_secret" "migration_secretkey" {
  key        = "cluster_homelab_garage_migration_secretkey"
  value      = garage_key.migration.secret_access_key
  project_id = var.bitwarden_project_id
  note       = "MinIO->Garage migration key's secret access key -- read+write on homelab-loki-chunks, homelab-authentik-media, homelab-terraform-state. Temporary: retire per this file's own top-of-file comment once the migration is done."
}

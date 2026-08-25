# ============================================================================
# TEMPORARY -- migration-only credentials. Two of them: garage_key.migration
# below, resolved from Bitwarden by in-cluster Jobs, and
# module.migration_loki_chunks_key at the bottom of this file, handed to the
# agent driving the migration as a file. They live in one file so they retire
# as one unit. DELETE THIS FILE WHOLESALE (and `terraform apply`) once the
# MinIO-to-Garage bucket migration is complete for all three buckets below
# (clusters#910's runbook, OPERATIONS.md "Runbook: migrate MinIO buckets to
# Garage"). Leaving either in place afterward is exactly the kind of standing
# broad-write privilege this project already rejected once, in dropping the
# Garage operator over its own cluster-wide Secret access -- a migration
# credential that outlives its migration is the same mistake in miniature.
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

# ============================================================================
# The agent-held migration credential. Scoped to homelab-loki-chunks alone,
# unlike garage_key.migration above.
# ============================================================================
#
# Why a second key rather than reusing garage_key.migration: the two have
# different holders. garage_key.migration is resolved from Bitwarden by
# in-cluster Jobs and never leaves the cluster. This one is delivered to the
# agent executing the migration as a file on its filesystem -- that agent has
# read-only Kubernetes access and no Bitwarden access, so it cannot reach the
# other key at all. Handing it garage_key.migration instead would put a
# credential for homelab-terraform-state -- the bucket meant to back every
# workspace's own state -- into a file on an agent's disk, which is the
# shared-key widening this scoping exists to avoid.
#
# read+write, not read alone: the agent runs the copy itself with this
# credential, and copying INTO homelab-loki-chunks needs write on the
# destination. What that grants, stated plainly: create, overwrite and delete
# any object in the bucket that holds every Loki chunk in production. Nothing
# narrower does the job -- a read-only grant fails at the one moment the
# credential is needed, and could not be widened mid-window either, since
# garage_bucket_permission changes are plan-and-apply and the holder has no
# apply capability.
#
# owner is withheld deliberately, not overlooked. Garage's permission model is
# flat -- read, write, owner (src/model/permission.rs BucketKeyPerm) -- and
# owner adds only bucket-level management: aliases, website access, deleting
# the bucket itself. The migration touches none of those, and object delete
# already comes with write. Same reasoning as modules/garage-key/key.tf's.
#
# Bitwarden write-back is the module's own, under its hardcoded prefix:
# garage_key_<key_name>_accesskey / _secretkey. Do not hand-create those two
# entries ahead of the first apply -- bitwarden_secret creates by ID and never
# adopts an entry by matching key name, so a pre-existing entry becomes a
# silent duplicate rather than an overwrite, the same trap spelled out for the
# two hand-named entries above.
module "migration_loki_chunks_key" {
  source = "../../modules/garage-key"

  key_name = "minio-garage-migration-loki-chunks"
  buckets = {
    loki_chunks = {
      bucket_id = module.loki_chunks.bucket.id
      read      = true
      write     = true
    }
  }
  bitwarden_project_id = var.bitwarden_project_id
}

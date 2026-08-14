# Both Loki buckets plus the one key that spans them, in one file rather than
# this workspace's usual bucket-<name>.tf-per-bucket layout (see
# bucket-authentik-media.tf, bucket-terraform-state.tf): a shared credential
# is only safe if a reader can see it's shared without hunting for it. Two
# separate bucket files plus a key call living elsewhere would make the
# sharing invisible at either individual call site -- exactly the
# unreadability modules/garage-key exists to fix. One file where both
# buckets and the key that reaches both of them sit together makes "which
# key reaches what" answerable by looking at one place. Don't expect one
# bucket per file just because every other file in this workspace is that
# shape -- this one isn't, because the buckets it holds aren't
# independently keyed.
#
# This also keeps the expected follow-up (dropping homelab-loki-ruler once
# apps#3611's Garage cutover confirms it's unneeded -- see loki_key's own
# comment below) a single-file edit: delete the loki_ruler bucket block and
# its entry in loki_key's buckets map, nothing else moves.

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

module "loki_ruler" {
  source = "../../modules/garage-bucket"

  bucket_name           = "${local.bucket_prefix}-loki-ruler"
  garage_admin_endpoint = var.garage_admin_endpoint
  garage_admin_token    = var.garage_admin_token
}

# One key for both buckets, not modules/garage-key's default one-key-per-bucket
# shape: Loki's Helm chart shares a single S3 credential across
# common.storage.s3 (chunks) and ruler.storage.s3 (ruler) -- see
# infrastructure/subsystems/observability-core/loki/helm-release-loki.yaml in
# the apps repo. Before the garage-key split, modules/garage-bucket could only
# ever mint one key per bucket, so chunks and ruler each got their own,
# independently-named "loki" key that could never have satisfied that shape --
# the defect ppat/homelab-ops-terraform#293 was reaching for a fix to.
# Consolidating them here is what modules/garage-key's buckets map exists
# for -- see that module's own comments -- not a demonstration of the
# capability.
#
# Loki's ruler itself no longer reads S3 at all (apps#3650 moved it to
# rulerConfig.storage.type: local), so #293's original premise (ruler needing
# S3 once Loki cut over to Garage) is gone and this grant on loki_ruler backs
# nothing live today. It's included anyway to land the correct shared-key
# shape in one step: a separate follow-up PR is expected to drop the
# homelab-loki-ruler bucket (and its entry below) entirely once that's
# confirmed stable. Until then, the bucket's lifetime (still exists) and the
# key's lifetime (already consolidated) simply aren't required to move in
# lockstep -- which is the whole point of splitting them apart.
module "loki_key" {
  source = "../../modules/garage-key"

  key_name = "loki"
  buckets = {
    loki_chunks = {
      bucket_id = module.loki_chunks.bucket.id
      read      = true
      write     = true
    }
    loki_ruler = {
      bucket_id = module.loki_ruler.bucket.id
      read      = true
      write     = true
    }
  }
  bitwarden_project_id = var.bitwarden_project_id
}

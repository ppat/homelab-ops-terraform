# NO object_expiration_days on loki_chunks. This is a refusal, not a gap -- do not add one.
# Loki's own compactor enforces retention for this bucket (retention_enabled: true in the Loki
# HelmRelease), and a bucket-side lifecycle rule cannot back that up, because the two cannot
# measure the same thing.
#
# Loki's retention is per-stream, not one number: clusters/homelab/services/logging/conf.d/
# loki-retention.yaml (homelab-ops-kubernetes-clusters) sets a 30d global with 24h overrides on
# {namespace="media"} and {service_name="coredns"}, and 8760h -- one year -- on
# {service_name="ci-diagnostics"}. A lifecycle rule can only test how old an object is; it sees
# neither stream labels nor log timestamps. Set it near 31d and it deletes the year-retention
# stream's chunks while Loki's index still references them, so queries past a month return
# errors (NoSuchKey from the store) rather than missing data -- invisible until someone drags a
# time picker back, and unrecoverable because that stream's source, GitHub Actions logs, is gone
# after 90 days. Set it to ~366d, the only value safe for every stream, and 99.9% of the bucket
# (the 24h and 30d data) sits for a year to protect a stream orders of magnitude smaller. Safe
# or useful, never both.
#
# Object age is the wrong predicate for a second, independent reason: the ci-diagnostics ingester
# writes retro-dated entries -- each stamped with the time the CI line was emitted, not the time
# it was scraped -- and backfills up to 90 days. An object written today can contain three-month-
# old data, so object age has no stable relationship to logical data age in either direction.
#
# Scope is this bucket. The module's object_expiration_days variable and its terracurl lifecycle
# seam are correct and stay exactly as they are.
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

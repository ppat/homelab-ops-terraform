# ============================================================================
# Loki's chunks key ALSO covers the ruler bucket -- one shared credential,
# not two. Revisit if apps#3650 lands: it moves Loki's ruler storage off S3
# entirely (a local-file sidecar instead), at which point ruler needs no
# bucket credential at all and this permission has nothing left to grant.
# ============================================================================
#
# Why one key needs both: Loki's Helm chart derives ruler.storage.s3 from the
# SAME rendered object as common.storage.s3 -- one ExternalSecret, one
# endpoint/key/secret triplet, wired only to loki.storage.s3.*. Whichever
# Garage key that ExternalSecret resolves to must therefore reach BOTH
# homelab-loki-chunks and homelab-loki-ruler, or the bucket it doesn't cover
# starts silently 403ing -- asymmetrically, since ruler activity is the low
# -traffic path that's easy to miss. Confirmed live: today's MinIO-hosted
# ConfigMap/loki (namespace logging) already shares one identical credential
# across both storage blocks; the Garage side needs to match that shape
# before Loki can cut over (apps#3611).
#
# Why here, not inside modules/garage-bucket: every OTHER bucket in this
# workspace (homelab-authentik-media, homelab-terraform-state) needs its key
# scoped to itself ONLY -- least privilege is the reason the one-key
# -per-bucket module shape exists, and it stays correct for those. Loki is
# the sole exception, and it needs to stay visibly exceptional: this
# resource is the one place a reader has to look to see which two buckets
# share a credential. Generalizing the module itself (a bucket-list
# variable, or a companion key-creating module) was considered and
# rejected: it would make the shared case reachable by editing one line
# inside a module every other bucket also calls -- exactly the accidental
# -widening this must stay incapable of. One instance of the pattern isn't
# enough to justify a standing abstraction; extract one if a second turns up.
#
# module.loki_chunks's key (not loki_ruler's) is the one reused here: both
# already exist live in Garage/Bitwarden (provisioned by #290), so reusing
# one avoids rotating a live credential entirely -- this resource only
# *adds* a permission, it doesn't touch either module's own key or Bitwarden
# entries. module.loki_ruler's own key is therefore left in place, now
# unused: retiring it cleanly needs Terraform's `removed` block (1.7+),
# which this workspace's pinned 1.6.6 doesn't have. Under 1.6.6 the only way
# to drop it from state is an out-of-band `terraform state rm` plus manual
# Garage/Bitwarden cleanup -- an operational step, not a plan-and-apply one.
# Left as a known, tracked cleanup rather than done silently as a side
# effect of this change.
resource "garage_bucket_permission" "loki_chunks_key_on_ruler_bucket" {
  bucket_id     = module.loki_ruler.bucket.id
  access_key_id = module.loki_chunks.owner_key.id
  read          = true
  write         = true
}

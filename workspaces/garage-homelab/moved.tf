# Bridges modules/garage-bucket's former garage_key/garage_bucket_permission/
# bitwarden_secret resources (owned access-key creation, bucket grants, and
# Bitwarden write-back moved out into modules/garage-key -- see that module
# and the bucket-*.tf/loki.tf files above for why) onto their new addresses,
# so `terraform apply` updates existing state in place instead of destroying
# and recreating three of the four live keys -- one of which
# (terraform_state_key) backs every workspace's own state-backend
# credentials. The fourth (loki_ruler's) is deliberately NOT bridged -- see
# the note at the bottom of this file.
#
# These live here, in the common parent workspace, not inside either module:
# per Terraform 1.6.6's own refactoring.mdx, "a module may only make moved
# statements about its own objects and objects of its child modules" -- a
# module cannot make a moved statement about a *sibling* module's resource,
# which is exactly this move (garage-bucket's old resource -> garage-key's
# new one). Only the workspace that calls both sees both sides.
#
# garage_bucket_permission's move is also a singleton -> for_each move
# (modules/garage-key's permission resource is for_each over var.buckets,
# where modules/garage-bucket's was a single resource) -- 1.6.6's docs cover
# combining an address change with an index change in one moved block under
# "Enabling for_each For a Resource".
#
# Safe to delete once a `terraform apply` against this workspace has picked
# these up and the state shows the new addresses -- keeping them past that
# point is harmless but pointless.

moved {
  from = module.authentik_media.garage_key.owner
  to   = module.authentik_media_key.garage_key.this
}

moved {
  from = module.authentik_media.garage_bucket_permission.owner
  to   = module.authentik_media_key.garage_bucket_permission.this["authentik_media"]
}

moved {
  from = module.authentik_media.bitwarden_secret.bucket_owner_accesskey
  to   = module.authentik_media_key.bitwarden_secret.accesskey
}

moved {
  from = module.authentik_media.bitwarden_secret.bucket_owner_secretkey
  to   = module.authentik_media_key.bitwarden_secret.secretkey
}

# loki_chunks's key moves and becomes the shared key -- key_name stays the
# byte-identical "loki" it already had (see loki.tf's loki_key comment for
# why it's now granted on both buckets, not just this one).
moved {
  from = module.loki_chunks.garage_key.owner
  to   = module.loki_key.garage_key.this
}

moved {
  from = module.loki_chunks.garage_bucket_permission.owner
  to   = module.loki_key.garage_bucket_permission.this["loki_chunks"]
}

moved {
  from = module.loki_chunks.bitwarden_secret.bucket_owner_accesskey
  to   = module.loki_key.bitwarden_secret.accesskey
}

moved {
  from = module.loki_chunks.bitwarden_secret.bucket_owner_secretkey
  to   = module.loki_key.bitwarden_secret.secretkey
}

# loki_ruler's own key, its permission, and its two Bitwarden entries are
# deliberately UNBRIDGED -- no moved block for
# module.loki_ruler.garage_key.owner, .garage_bucket_permission.owner, or
# either .bitwarden_secret.bucket_owner_*key. `terraform plan` will show all
# four as destroyed. That's intended, not an oversight: apps#3650 moved
# Loki's ruler to local file-based rule delivery (rulerConfig.storage.type:
# local), so this key backed nothing live even before this PR, and
# loki_key above now grants the surviving chunks key read+write on
# homelab-loki-ruler instead -- the shape modules/garage-bucket's
# one-key-per-bucket design could never express (ppat/homelab-ops-terraform#293).
# Destroying an unused key costs nothing; the zero-destroy bar this file
# otherwise holds every other resource to is specifically about not
# rotating a credential something depends on, and nothing depends on this
# one.

moved {
  from = module.terraform_state.garage_key.owner
  to   = module.terraform_state_key.garage_key.this
}

moved {
  from = module.terraform_state.garage_bucket_permission.owner
  to   = module.terraform_state_key.garage_bucket_permission.this["terraform_state"]
}

moved {
  from = module.terraform_state.bitwarden_secret.bucket_owner_accesskey
  to   = module.terraform_state_key.bitwarden_secret.accesskey
}

moved {
  from = module.terraform_state.bitwarden_secret.bucket_owner_secretkey
  to   = module.terraform_state_key.bitwarden_secret.secretkey
}

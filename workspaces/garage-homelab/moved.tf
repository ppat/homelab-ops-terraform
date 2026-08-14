# Bridges modules/garage-bucket's former garage_key/garage_bucket_permission/
# bitwarden_secret resources (owned access-key creation, bucket grants, and
# Bitwarden write-back moved out into modules/garage-key -- see that module
# and the bucket-*.tf files above for why) onto their new addresses, so
# `terraform apply` updates existing state in place instead of destroying
# and recreating three live keys -- one of which (terraform_state_key)
# backs every workspace's own state-backend credentials.
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

# loki_chunks's key moves and keeps its byte-identical "loki" key_name (see
# bucket-loki-chunks.tf's loki_key comment for why that name doesn't match
# this module's own naming convention).
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

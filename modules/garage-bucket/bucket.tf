resource "garage_bucket" "bucket" {
  global_alias = var.bucket_name

  # Garage has no S3 bucket-policy support, so anonymous public read only exists
  # via this website config. Reachability is automatic once enabled -- Garage's
  # [s3_web] endpoint resolves a bucket-name-prefixed subdomain of its
  # configured root_domain straight to this bucket's global_alias (no second
  # alias needed, see var.anonymous_read_enabled's description).
  website_enabled        = var.anonymous_read_enabled
  website_index_document = var.anonymous_read_enabled ? "index.html" : null

  # global_alias carries RequiresReplace() (jkossis/garage v1.0.5,
  # internal/provider/bucket_resource.go), and its Read() takes
  # GlobalAliases[0] off Garage's CRDT alias map -- unordered, so a stray
  # second alias makes refreshes flip global_alias and force a replace (see
  # ppat/homelab-ops-terraform#297, where this destroyed nothing only because
  # the bucket held zero objects). Any RequiresReplace() attribute the
  # provider misreads can do the same, and a replacement is a destroy.
  # prevent_destroy turns that plan into a hard error instead of a `yes`
  # someone skims past.
  #
  # Terraform 1.6.6 can't take a variable in prevent_destroy, so this applies
  # to every caller of this module, not just whichever bucket trips it.
  # To deliberately destroy/replace a bucket (e.g. decommissioning one):
  # edit this block to `prevent_destroy = false` in this module's source,
  # apply the affected workspace(s), then revert this file to
  # `prevent_destroy = true` in a follow-up commit. The window is open for
  # every bucket this module provisions, not just the one being destroyed --
  # keep it short.
  #
  # What this does NOT catch: `terraform state rm` followed by a fresh
  # create, a `-target`ed destroy, direct Garage admin-API deletion, or this
  # resource/module call being deleted from the calling workspace outright --
  # verified empirically that with the resource removed from config,
  # `terraform plan` destroys it with no error. prevent_destroy only holds
  # "as long as the argument remains set to true in the configuration for
  # that resource" (Terraform's own docs); once the resource has no
  # configuration at all, there's nothing left to hold it.
  lifecycle {
    prevent_destroy = true
  }
}

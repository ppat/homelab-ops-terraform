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
  # MOST IMPORTANT GAP: this does NOT catch the module call for a bucket
  # (e.g. this whole `module "authentik_media" { ... }` block) being deleted
  # from the calling workspace -- verified empirically on Terraform 1.6.6,
  # in a throwaway config, that removing a prevent_destroy-guarded resource
  # from configuration entirely makes `terraform plan` destroy it with no
  # error at all (a plain "not in configuration" destroy, exit 0). That's
  # arguably the single most likely real way a bucket here gets deleted, and
  # this guard does not stop it. prevent_destroy only holds "as long as the
  # argument remains set to true in the configuration for that resource"
  # (Terraform's own docs) -- once the resource has no configuration at all,
  # there's nothing left to hold it.
  #
  # Also does not catch: `terraform state rm` followed by a fresh create, a
  # `-target`ed destroy that excludes this resource from the plan's scope,
  # or direct Garage admin-API deletion -- all bypass Terraform's plan
  # entirely.

  # website_error_document is never set in this module's config, so it
  # resolves to null -- but the provider's Read() maps Garage's
  # errorDocument: null back to "" in state, so config and state disagree
  # forever, on every apply, for every website-enabled bucket
  # (terraform show -json, observed and recurring after an apply that
  # already "fixed" it):
  #   before: { "website_error_document": "",   "website_index_document": "index.html" }
  #   after:  { "website_error_document": null, "website_index_document": "index.html" }
  # This is provider empty-string-vs-null normalization, not this module
  # declining to manage a real setting -- there's no error-document feature
  # being withheld. ignore_changes states that truth. Left unhandled, a plan
  # that never comes back clean is exactly the training effect
  # prevent_destroy above exists to counter: an operator who's used to
  # skimming past a permanent, meaningless diff is the operator who skims
  # past the destroy line too.
  #
  # If a real error document is ever wanted for a bucket: remove
  # website_error_document from ignore_changes below first -- otherwise
  # whatever value config sets will be silently ignored.
  lifecycle {
    prevent_destroy = true
    ignore_changes  = [website_error_document]
  }
}

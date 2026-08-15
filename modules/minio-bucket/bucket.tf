resource "minio_s3_bucket" "bucket" {
  bucket = var.bucket_name
  acl    = "private"

  # bucket is ForceNew (aminueza/minio v3.38.6, minio/resource_minio_s3_bucket.go)
  # -- same class of risk that hit modules/garage-bucket (ppat/homelab-ops-terraform#297):
  # any attribute with ForceNew/RequiresReplace turns a provider misread into a
  # replace, and a replace is a destroy. This bucket backs Loki chunks, CNPG and
  # Longhorn backups, and the Terraform state backend every workspace reads --
  # prevent_destroy turns that plan into a hard error instead of a `yes` someone
  # skims past.
  #
  # Terraform 1.6.6 can't take a variable in prevent_destroy, so this applies to
  # every caller of this module, not just whichever bucket trips it.
  # To deliberately destroy/replace a bucket (e.g. decommissioning one): edit
  # this block to `prevent_destroy = false` in this module's source, apply the
  # affected workspace(s), then revert this file to `prevent_destroy = true` in
  # a follow-up commit. The window is open for every bucket this module
  # provisions, not just the one being destroyed -- keep it short.
  #
  # What this does NOT catch: `terraform state rm` followed by a fresh create,
  # a `-target`ed destroy, direct MinIO admin-API/mc deletion, or this
  # resource/module call being deleted from the calling workspace outright --
  # verified empirically that with the resource removed from config,
  # `terraform plan` destroys it with no error. prevent_destroy only holds "as
  # long as the argument remains set to true in the configuration for that
  # resource" (Terraform's own docs); once the resource has no configuration at
  # all, there's nothing left to hold it.
  lifecycle {
    prevent_destroy = true
  }
}

resource "minio_s3_bucket_policy" "bucket_policy" {
  count  = var.bucket_policy != null ? 1 : 0
  bucket = minio_s3_bucket.bucket.bucket
  policy = var.bucket_policy
}

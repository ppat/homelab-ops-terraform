resource "minio_ilm_policy" "bucket_lifecycle" {
  count  = var.object_expiration_days != null ? 1 : 0
  bucket = minio_s3_bucket.bucket.bucket

  rule {
    id         = "expire-after-${var.object_expiration_days}-days"
    expiration = "${var.object_expiration_days}d"
  }
}

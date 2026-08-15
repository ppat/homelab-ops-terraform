resource "minio_s3_bucket" "bucket" {
  bucket = var.bucket_name
  acl    = "private"
}

resource "minio_s3_bucket_policy" "bucket_policy" {
  count  = var.bucket_policy != null ? 1 : 0
  bucket = minio_s3_bucket.bucket.bucket
  policy = var.bucket_policy
}

output "bucket" {
  description = "Created bucket"
  value       = minio_s3_bucket.bucket
}

output "owner" {
  description = "Created IAM user"
  value       = minio_iam_user.owner
  sensitive   = true
}

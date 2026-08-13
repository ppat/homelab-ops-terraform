output "bucket" {
  description = "Created bucket"
  value       = garage_bucket.bucket
}

output "owner_key" {
  description = "Created access key"
  value       = garage_key.owner
  sensitive   = true
}

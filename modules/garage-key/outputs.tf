output "key" {
  description = "Created access key"
  value       = garage_key.this
  sensitive   = true
}

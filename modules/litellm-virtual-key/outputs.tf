output "key" {
  description = "Created LiteLLM virtual key, including its plaintext token. Sensitive because the underlying `key` attribute is sensitive in the provider schema (GET /key/info never returns it — this is the only place that plaintext is ever available). Consumers should read it from Bitwarden (apikey_litellm_<consumer>), not from Terraform state."
  value       = litellm_key.this
  sensitive   = true
}

output "key_id" {
  description = "Non-sensitive hash identifier for this key (litellm_key.this.id), safe to reference for cross-checking against the Admin UI or logs without exposing the plaintext token"
  value       = litellm_key.this.id
}

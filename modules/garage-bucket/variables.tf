variable "bucket_name" {
  description = "Name of the Garage bucket to create (its global alias)"
  type        = string
}

variable "object_expiration_days" {
  description = "Number of days after which objects expire. If null, no expiration rule is applied. Implemented via a REST seam, not the garage provider itself -- see lifecycle.tf."
  type        = number
  default     = null
}

variable "anonymous_read_enabled" {
  description = <<-EOT
    When true, enables anonymous public read for this bucket via Garage's [s3_web]
    website endpoint (Garage has no S3 bucket-policy support, unlike MinIO -- this
    is the only mechanism it offers). Reachability is automatic once enabled:
    Garage's [s3_web] endpoint resolves any "$${bucket_name}.<root_domain>" Host
    header to $${bucket_name} by suffix match against root_domain regardless of
    a leading dot (Garage strips it before comparing) -- so it lands straight on
    this bucket's own existing global_alias (bucket_name). No second alias or
    per-bucket hostname needs to be configured here; that suffix matching isn't
    new or apps-repo-gated, it's how [s3_web] already works. What was actually
    missing, and is added by ppat/homelab-ops-kubernetes-apps#3681, is purely
    Kubernetes-side: an Ingress rule that routes the wildcard host at all, and a
    wildcard certificate for it (the default cert covers only one label). See
    ppat/homelab-ops-kubernetes-apps#3652 for where this limitation was first
    recorded.

    False (the default) disables website access entirely.
  EOT
  type        = bool
  default     = false
}

# --- REST seam inputs (lifecycle.tf) ---

variable "garage_admin_endpoint" {
  description = "Base URL of the Garage Admin API -- reachable via the garage-admin Ingress; see the workspace's terraform.tf for the host and how to set this, and why only /v2 is exposed. Used only by the lifecycle REST seam. The garage provider itself gets this from the GARAGE_ENDPOINT env var; terracurl has no such implicit config and needs it passed explicitly."
  type        = string
}

variable "garage_admin_token" {
  description = "Garage admin API bearer token, used only by the lifecycle REST seam to authenticate its direct admin API calls. The garage provider itself gets this from the GARAGE_TOKEN env var."
  type        = string
  sensitive   = true
}

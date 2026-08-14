variable "bitwarden_project_id" {
  description = "Bitwarden Secrets project under which to save the owner key's access and secret keys"
  type        = string
  sensitive   = true
}

variable "bucket_name" {
  description = "Name of the Garage bucket to create (its global alias)"
  type        = string
}

variable "owner_key_name" {
  description = "Human-friendly name for the Garage access key that owns this bucket"
  type        = string
}

variable "object_expiration_days" {
  description = "Number of days after which objects expire. If null, no expiration rule is applied. Implemented via a REST seam, not the garage provider itself -- see lifecycle.tf."
  type        = number
  default     = null
}

variable "anonymous_read_hostname" {
  description = <<-EOT
    When set, enables anonymous public read for this bucket via Garage's [s3_web]
    website endpoint (Garage has no S3 bucket-policy support, unlike MinIO -- this
    is the only mechanism it offers) and adds this value as a SECOND global alias
    on the bucket, alongside bucket_name -- implemented via a REST seam, not the
    garage provider itself, see alias.tf for why. Must exactly match the Host
    header Garage's web endpoint will actually receive for this bucket to be
    reachable: in this estate that's the storage-core module's own web Ingress
    host (garage-web.$${domain_name}).

    At most one bucket across the whole Garage instance can use this at a time --
    a deliberate, current choice in the apps-repo module's own [s3_web]/Ingress
    configuration, not a property of this variable, this module, or Terraform,
    and not a Garage constraint either. It's liftable: see
    ppat/homelab-ops-kubernetes-apps#3652 for what produces the limit today and
    what changing it would take. Don't look for the fix here.

    Null (the default) disables website access entirely, the only valid value for
    every bucket that doesn't need public reads.
  EOT
  type        = string
  default     = null
}

# --- REST seam inputs (lifecycle.tf, alias.tf) ---

variable "garage_admin_endpoint" {
  description = "Base URL of the Garage Admin API -- reachable via the garage-admin Ingress; see the workspace's terraform.tf for the host and how to set this, and why only /v2 is exposed. Used only by the lifecycle/web-alias REST seams. The garage provider itself gets this from the GARAGE_ENDPOINT env var; terracurl has no such implicit config and needs it passed explicitly."
  type        = string
}

variable "garage_admin_token" {
  description = "Garage admin API bearer token, used only by the lifecycle/web-alias REST seams to authenticate their direct admin API calls. The garage provider itself gets this from the GARAGE_TOKEN env var."
  type        = string
  sensitive   = true
}

variable "bitwarden_project_id" {
  description = "Bitwarden Secrets project under which to save the owner's access and secret keys"
  type        = string
  sensitive   = true
}

variable "bucket_name" {
  description = "Name of the MinIO bucket to create"
  type        = string
}

variable "bucket_policy" {
  description = "Policy to apply to the bucket. If null, no bucket policy will be created"
  type        = string
  default     = null
}

variable "owner_username" {
  description = "Bucket owner"
  type        = string
}

variable "owner_policy" {
  description = "Policy to apply to the owner. If null, default owner policy will be applied."
  type        = string
  default     = null
}

variable "key_name" {
  description = <<-EOT
    Human-friendly name for this Garage access key -- passed unchanged to
    garage_key.this's name argument. For a key migrated from
    modules/garage-bucket (see the workspace's moved.tf), this MUST be the
    exact string the live key already has: name carries RequiresReplace in
    jkossis/garage v1.0.5 (destroy + recreate, minting a new
    secret_access_key), and Update() unconditionally errors -- there is no
    in-place rename on the Garage side, unlike Bitwarden's.
  EOT
  type        = string
}

variable "buckets" {
  description = <<-EOT
    Buckets this key is granted access to, keyed by a caller-chosen short
    name (used as the garage_bucket_permission for_each key, so pick
    something stable -- renaming a key here replaces that one permission,
    not the access key itself). Each entry grants read and/or write on one
    bucket; there is no owner-level grant -- see key.tf.
  EOT
  type = map(object({
    bucket_id = string
    read      = bool
    write     = bool
  }))
}

variable "bitwarden_project_id" {
  description = "Bitwarden Secrets project under which to save this key's access and secret keys"
  type        = string
  sensitive   = true
}

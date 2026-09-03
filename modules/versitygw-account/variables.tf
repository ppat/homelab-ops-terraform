variable "accounts" {
  description = <<-EOT
    Every account the store should have, keyed by a stable name. Adding a consumer is an
    entry here and nothing else; the count is never a property of this module.

    `bucket` is the bucket that account owns, created and assigned to it. Null for an
    account that owns nothing -- the WebUI's admin account is the case that exists for.
  EOT
  type = map(object({
    bucket = optional(string)
    role   = optional(string, "user")
  }))

  validation {
    condition     = alltrue([for a in var.accounts : contains(["user", "userplus", "admin"], a.role)])
    error_message = "Each account's role must be one of: user, userplus, admin."
  }

  validation {
    condition     = length(distinct(compact([for a in var.accounts : a.bucket]))) == length(compact([for a in var.accounts : a.bucket]))
    error_message = "Two accounts may not own the same bucket."
  }

  # The admin CLI reports accounts in a whitespace-delimited table and carries bucket and
  # owner in a URL query string, so anything outside this shape breaks parsing downstream.
  validation {
    condition     = alltrue([for b in compact([for a in var.accounts : a.bucket]) : can(regex("^[a-z0-9][a-z0-9.-]{2,62}$", b))])
    error_message = "Each bucket name must be 3-63 characters of lowercase letters, digits, dots and hyphens, starting alphanumeric."
  }

  # The Bitwarden key formula strips non-alphanumerics, so `webui-admin` and `webuiadmin`
  # would write to the same entries -- and Bitwarden does not enforce key uniqueness, so the
  # overwrite would be silent.
  validation {
    condition     = length(distinct([for name in keys(var.accounts) : lower(replace(name, "/[^a-zA-Z0-9]/", ""))])) == length(keys(var.accounts))
    error_message = "Account names must stay distinct after non-alphanumeric characters are stripped, since that is what forms their Bitwarden key names."
  }
}

variable "bitwarden_project_id" {
  description = "Bitwarden Secrets Manager project the generated credentials are written into."
  type        = string
  sensitive   = true
}

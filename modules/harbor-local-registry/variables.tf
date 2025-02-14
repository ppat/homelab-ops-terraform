variable "auto_sbom_generation" {
  type        = bool
  description = "Automatically generate sbom for images pushed to this"
  default     = false
}

variable "name" {
  type        = string
  description = "Name of the registry project"
}

variable "public" {
  type        = bool
  description = "Whether the registry is public"
  default     = false
}

variable "storage_quota" {
  type        = number
  description = "Storage quota in bytes"
  default     = -1
}

variable "vulnerability_scanning" {
  type        = bool
  description = "enable vulnerability scanning"
  default     = true
}

variable "retention_policy" {
  type = object({
    always_retain_tags     = list(string)
    most_recently_pulled   = number
    n_days_since_last_pull = number
    n_days_since_last_push = number
  })
  default = {
    always_retain_tags     = ["latest"]
    most_recently_pulled   = 1
    n_days_since_last_pull = 7
    n_days_since_last_push = 7
  }
}

variable "project_name" {
  type        = string
  description = "Name of the project"
}

variable "registry_name" {
  type        = string
  description = "Name of the registry"
}

variable "registry_endpoint" {
  type        = string
  description = "Registry endpoint URL"
}

variable "registry_provider" {
  type        = string
  description = "Type of registry (e.g., docker-hub, github, etc)"
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
    most_recently_pulled   = number
    n_days_since_last_pull = number
  })
  default = {
    most_recently_pulled   = 3
    n_days_since_last_pull = 7
  }
}

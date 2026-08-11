variable "bitwarden_project_id" {
  type      = string
  sensitive = true
}

variable "litellm_api_base" {
  type = string
}

variable "litellm_master_key" {
  type      = string
  sensitive = true
}

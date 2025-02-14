variable "bitwarden_project_id" {
  type      = string
  sensitive = true
}

variable "clientid_coder" {
  type      = string
  sensitive = true
}

variable "clientid_grafana" {
  type      = string
  sensitive = true
}

variable "clientid_harbor" {
  type      = string
  sensitive = true
}

variable "clientid_miniohomelab" {
  type      = string
  sensitive = true
}

variable "clientid_minionas" {
  type      = string
  sensitive = true
}

variable "dns_zone" {
  type = string
}

variable "signing_key" {
  type    = string
  default = "jwt-signing"
}

variable "bitwarden_project_id" {
  type      = string
  sensitive = true
}

variable "dns_zone" {
  type = string
}

variable "signing_key" {
  type    = string
  default = "jwt-signing" # "authentik Self-signed Certificate"
}

variable "grafana_client_id" {
  type = string
}

variable "harbor_clientid" {
  type = string
}

variable "minio_homelab_clientid" {
  type = string
}

variable "minio_nas_clientid" {
  type = string
}

variable "homelab_bot_app_id" {
  type      = string
  sensitive = true
}

variable "homelab_bot_app_private_key" {
  type      = string
  sensitive = true
}

variable "gh_release_token" {
  type      = string
  sensitive = true
}

variable "ansible_galaxy_api_token" {
  type      = string
  sensitive = true
}

variable "dockerhub_username" {
  type      = string
  sensitive = true
}

variable "dockerhub_token" {
  type      = string
  sensitive = true
}

# tflint-ignore: terraform_unused_declarations
variable "harbor_username" {
  type      = string
  sensitive = true
}

# tflint-ignore: terraform_unused_declarations
variable "harbor_password" {
  type      = string
  sensitive = true
}

# tflint-ignore: terraform_unused_declarations
variable "dns_zone" {
  type = string
}

variable "clientid_tailscale" {
  type      = string
  sensitive = true
}

variable "clientsecret_tailscale" {
  type      = string
  sensitive = true
}

variable "renovate_app_id" {
  type      = string
  sensitive = true
}

variable "renovate_app_private_key" {
  type      = string
  sensitive = true
}

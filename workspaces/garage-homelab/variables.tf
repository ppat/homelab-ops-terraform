variable "bitwarden_project_id" {
  type      = string
  sensitive = true
}

# See terraform.tf's provider "garage" block for how to obtain and pass these.
variable "garage_admin_endpoint" {
  type = string
}

variable "garage_admin_token" {
  type      = string
  sensitive = true
}

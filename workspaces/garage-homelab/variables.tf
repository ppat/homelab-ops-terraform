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

variable "garage_web_hostname" {
  description = <<-EOT
    Hostname Garage's [s3_web] website endpoint actually receives via Ingress for
    this cluster (garage-web.$${domain_name} in the apps repo's
    infrastructure/subsystems/storage-core/garage module). Passed through to
    homelab-authentik-media as its anonymous-read alias.

    Only one bucket in this workspace can use this value -- a deliberate, current
    choice in the apps-repo module's own [s3_web]/Ingress configuration, not a
    property of this variable, this workspace, or Terraform, and not a Garage
    constraint either. It's liftable: see
    ppat/homelab-ops-kubernetes-apps#3652 for what produces the limit today and
    what changing it would take. Don't look for the fix here.
  EOT
  type        = string
}

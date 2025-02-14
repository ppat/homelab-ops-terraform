resource "harbor_registry" "remote_registry" {
  name          = var.registry_name
  endpoint_url  = var.registry_endpoint
  insecure      = false
  provider_name = var.registry_provider
}

resource "harbor_project" "project" {
  name                   = var.project_name
  public                 = true
  registry_id            = harbor_registry.remote_registry.registry_id
  storage_quota          = var.storage_quota
  vulnerability_scanning = var.vulnerability_scanning
}

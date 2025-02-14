resource "harbor_project" "project" {
  name                   = var.name
  auto_sbom_generation   = var.auto_sbom_generation
  force_destroy          = false
  public                 = var.public
  storage_quota          = var.storage_quota
  vulnerability_scanning = var.vulnerability_scanning
}

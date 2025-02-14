module "registry_library" {
  source               = "../../modules/harbor-local-registry"
  name                 = "library"
  auto_sbom_generation = true
  public               = true
}

module "registry_build_cache" {
  source                 = "../../modules/harbor-local-registry"
  name                   = "build-cache"
  auto_sbom_generation   = false
  public                 = true
  vulnerability_scanning = false
  retention_policy = {
    always_retain_tags     = ["cache-latest", "main"]
    most_recently_pulled   = 1
    n_days_since_last_pull = 7
    n_days_since_last_push = 2
  }
}

module "registry_proxy_dockerhub" {
  source            = "../../modules/harbor-proxy-registry"
  project_name      = "docker.io"
  registry_name     = "dockerhub-registry"
  registry_endpoint = "https://hub.docker.com"
  registry_provider = "docker-hub"
}

module "registry_proxy_ghcr" {
  source            = "../../modules/harbor-proxy-registry"
  project_name      = "ghcr.io"
  registry_name     = "github-registry"
  registry_endpoint = "https://ghcr.io"
  registry_provider = "github"
}

module "registry_proxy_quay" {
  source            = "../../modules/harbor-proxy-registry"
  project_name      = "quay.io"
  registry_name     = "quay-registry"
  registry_endpoint = "https://quay.io"
  registry_provider = "docker-registry"
}

module "registry_proxy_k8s" {
  source            = "../../modules/harbor-proxy-registry"
  project_name      = "registry.k8s.io"
  registry_name     = "k8s-registry"
  registry_endpoint = "https://registry.k8s.io"
  registry_provider = "docker-registry"
}

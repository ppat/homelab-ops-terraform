module "repo_homelab_ops_kubernetes_clusters" {
  source = "../../modules/github-repository"
  repository = {
    name        = "homelab-ops-kubernetes-clusters"
    description = "Kubernetes Cluster configuration for my homelab"
    visibility  = "public"
  }
  actions_allowed = [
    "docker://ghcr.io/allenporter/flux-local:*",
    "fluxcd/flux2/action@*",
    "helm/kind-action@*",
    "jdx/mise-action@*",
    "kyverno/action-install-chainsaw@*",
    "mshick/add-pr-comment@*",
    "tj-actions/changed-files@*"
  ]
  environment_secrets = {
    release = {
      HOMELAB_BOT_APP_ID          = data.bitwarden_secret.homelab_bot_app_id.value
      HOMELAB_BOT_APP_PRIVATE_KEY = data.bitwarden_secret.homelab_bot_app_private_key.value
    }
    renovate = {
      DOCKERHUB_USERNAME       = data.bitwarden_secret.dockerhub_username.value
      DOCKERHUB_TOKEN          = data.bitwarden_secret.dockerhub_token.value
      RENOVATE_APP_ID          = data.bitwarden_secret.renovate_app_id.value
      RENOVATE_APP_PRIVATE_KEY = data.bitwarden_secret.renovate_app_private_key.value
    }
  }
}

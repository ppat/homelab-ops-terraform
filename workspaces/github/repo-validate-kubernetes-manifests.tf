module "repo_validate_kubernetes_manifests" {
  source = "../../modules/github-repository"
  repository = {
    name        = "validate-kubernetes-manifests"
    description = "A Github Action and a Pre-Commit Hook for validating Kubernetes manifests"
    visibility  = "public"
  }
  actions_allowed = [
    "googleapis/release-please-action@*",
    "jdx/mise-action@*",
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
  force_push_bypassers = [data.github_user.current.node_id]
}

module "repo_github_workflows" {
  source = "../../modules/github-repository"
  repository = {
    name        = "github-workflows"
    description = "Reusable github workflows"
    visibility  = "public"
  }
  actions_allowed = [
    "docker/build-push-action@*",
    "docker/setup-buildx-action@*",
    "docker/login-action@*",
    "docker/metadata-action@*",
    "docker/setup-qemu-action@*",
    "hadolint/hadolint-action@*",
    "jdx/mise-action@*",
    "peter-evans/dockerhub-description@*",
    "tailscale/github-action@*",
    "tj-actions/changed-files@*"
  ]
  environment_secrets = {
    renovate = {
      DOCKERHUB_USERNAME       = data.bitwarden_secret.dockerhub_username.value
      DOCKERHUB_TOKEN          = data.bitwarden_secret.dockerhub_token.value
      RENOVATE_APP_ID          = data.bitwarden_secret.renovate_app_id.value
      RENOVATE_APP_PRIVATE_KEY = data.bitwarden_secret.renovate_app_private_key.value
    }
  }
}

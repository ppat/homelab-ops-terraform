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
      RENOVATE_APP_ID          = var.renovate_app_id
      RENOVATE_APP_PRIVATE_KEY = file(var.renovate_app_private_key)
      DOCKERHUB_USERNAME       = var.dockerhub_username
      DOCKERHUB_TOKEN          = var.dockerhub_token
    }
  }
}

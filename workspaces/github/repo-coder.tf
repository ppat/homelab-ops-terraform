module "repo_coder" {
  source = "../../modules/github-repository"
  repository = {
    name        = "coder"
    description = "Templates and Images for Coder Workspaces"
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
  actions_secrets = {
    HOMELAB_BOT_APP_ID          = var.homelab_bot_app_id
    HOMELAB_BOT_APP_PRIVATE_KEY = file(var.homelab_bot_app_private_key)
    # TODO: add these
    # CODER_EMAIL
    # CODER_PASSWORD
    # CODER_URL
    # CONTAINER_REGISTRY
    # CONTAINER_REGISTRY_PASSWORD
    # CONTAINER_REGISTRY_USERNAME
    # GH_RELEASES_TOKEN
    # TAILSCALE_OAUTH_CLIENT_ID
    # TAILSCALE_OAUTH_SECRET
  }
  topics = [
    "cde",
    "cloud-development-environment",
    "coder",
    "homelab"
  ]
}

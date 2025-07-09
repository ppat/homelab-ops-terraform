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
    CODER_EMAIL                 = data.bitwarden_secret.coder_ci_email.value
    CODER_PASSWORD              = data.bitwarden_secret.coder_ci_password.value
    CODER_URL                   = "https://coder.homelab.${data.bitwarden_secret.dns_zone.value}"
    CONTAINER_REGISTRY          = "harbor.nas.${data.bitwarden_secret.dns_zone.value}"
    CONTAINER_REGISTRY_USERNAME = data.bitwarden_secret.harbor_robot_username.value
    CONTAINER_REGISTRY_PASSWORD = data.bitwarden_secret.harbor_robot_password.value
    GH_RELEASES_TOKEN           = data.bitwarden_secret.github_release_token.value
    HOMELAB_BOT_APP_ID          = data.bitwarden_secret.homelab_bot_app_id.value
    HOMELAB_BOT_APP_PRIVATE_KEY = data.bitwarden_secret.homelab_bot_app_private_key.value
    # TAILSCALE_OAUTH_CLIENT_ID   = data.bitwarden_secret.tailscale_clientid.value
    # TAILSCALE_OAUTH_SECRET      = data.bitwarden_secret.tailscale_client_secret.value
  }
  environment_secrets = {
    renovate = {
      DOCKERHUB_USERNAME       = data.bitwarden_secret.dockerhub_username.value
      DOCKERHUB_TOKEN          = data.bitwarden_secret.dockerhub_token.value
      RENOVATE_APP_ID          = data.bitwarden_secret.renovate_app_id.value
      RENOVATE_APP_PRIVATE_KEY = data.bitwarden_secret.renovate_app_private_key.value
    }
  }
  require_signed_commits = false
  topics = [
    "cde",
    "cloud-development-environment",
    "coder",
    "homelab"
  ]
}

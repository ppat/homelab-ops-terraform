module "repo_obsidian_tools" {
  source = "../../modules/github-repository"
  repository = {
    name        = "obsidian-tools"
    description = ""
    visibility  = "private"
  }
  actions_allowed = [
    "docker/build-push-action@*",
    "docker/setup-buildx-action@*",
    "docker/login-action@*",
    "docker/metadata-action@*",
    "docker/setup-qemu-action@*",
    "googleapis/release-please-action@*",
    "jdx/mise-action@*",
    "tailscale/github-action@*",
    "tj-actions/changed-files@*"
  ]
  actions_secrets = {
    CONTAINER_REGISTRY          = "harbor.nas.${data.bitwarden_secret.dns_zone.value}"
    CONTAINER_REGISTRY_USERNAME = data.bitwarden_secret.harbor_robot_username.value
    CONTAINER_REGISTRY_PASSWORD = data.bitwarden_secret.harbor_robot_password.value
    DOCKERHUB_USERNAME          = data.bitwarden_secret.dockerhub_username.value
    DOCKERHUB_TOKEN             = data.bitwarden_secret.dockerhub_token.value
    HOMELAB_BOT_APP_ID          = data.bitwarden_secret.homelab_bot_app_id.value
    HOMELAB_BOT_APP_PRIVATE_KEY = data.bitwarden_secret.homelab_bot_app_private_key.value
    RENOVATE_APP_ID             = data.bitwarden_secret.renovate_app_id.value
    RENOVATE_APP_PRIVATE_KEY    = data.bitwarden_secret.renovate_app_private_key.value
    TAILSCALE_OAUTH_CLIENT_ID   = data.bitwarden_secret.tailscale_githubactionsci_clientid.value
    TAILSCALE_OAUTH_SECRET      = data.bitwarden_secret.tailscale_githubactionsci_clientsecret.value
  }
  actions_variables = {
    CONTAINER_REGISTRY_CACHE_PATH = "build-cache"
    CONTAINER_REGISTRY_PATH       = "library"
  }
}

module "repo_images" {
  source = "../../modules/github-repository"
  repository = {
    name        = "images"
    description = "Various container images for homelab and other usecases"
    visibility  = "public"
  }
  actions_allowed = [
    "aquaproj/aqua-installer@*",
    "aquaproj/update-checksum-action@*",
    "aquaproj/update-checksum-workflow/.github/workflows/update-checksum.yaml@*",
    "docker/build-push-action@*",
    "docker/setup-buildx-action@*",
    "docker/login-action@*",
    "docker/metadata-action@*",
    "docker/setup-qemu-action@*",
    "hadolint/hadolint-action@*",
    "jdx/mise-action@*",
    "peter-evans/dockerhub-description@*",
    "suzuki-shunsuke/github-token-action@*",
    "tailscale/github-action@*",
    "tibdex/github-app-token@*",
    "tj-actions/changed-files@*"
  ]
  actions_secrets = {
    # TODO: re-enable and fix
    # CONTAINER_REGISTRY          = "harbor.nas.${var.dns_zone}"
    # CONTAINER_REGISTRY_USERNAME = var.harbor_username
    # CONTAINER_REGISTRY_PASSWORD = var.harbor_password
    DOCKERHUB_USERNAME          = var.dockerhub_username
    DOCKERHUB_TOKEN             = var.dockerhub_token
    HOMELAB_BOT_APP_ID          = var.homelab_bot_app_id
    HOMELAB_BOT_APP_PRIVATE_KEY = file(var.homelab_bot_app_private_key)
    TAILSCALE_OAUTH_CLIENT_ID   = var.clientid_tailscale
    TAILSCALE_OAUTH_SECRET      = var.clientsecret_tailscale
  }
  homepage_url = "https://hub.docker.com/u/ppatlabs"
  topics = [
    "amd64",
    "arm64",
    "bitwarden",
    "docker",
    "freeradius",
    "images",
    "k8s-at-home",
    "multiarch",
  ]
}

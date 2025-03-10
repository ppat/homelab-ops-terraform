module "repo_images" {
  source = "../../modules/github-repository"
  repository = {
    name        = "images"
    description = "Various container images for homelab and other usecases"
    visibility  = "public"
  }
  actions_allowed = [
    "aquaproj/update-checksum-workflow@*",
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
    # CONTAINER_REGISTRY
    # CONTAINER_REGISTRY_PASSWORD
    # CONTAINER_REGISTRY_USERNAME
    # DOCKERHUB_TOKEN
    # DOCKERHUB_USERNAME
    # TAILSCALE_OAUTH_CLIENT_ID
    # TAILSCALE_OAUTH_SECRET
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

module "repo_homelab_ops_packer" {
  source = "../../modules/github-repository"
  repository = {
    name        = "homelab-ops-packer"
    description = "Packer based image builds for homelab"
    visibility  = "public"
  }
  actions_allowed = [
    "jdx/mise-action@*",
    "tailscale/github-action@*",
    "tj-actions/changed-files@*"
  ]
  actions_secrets = {
    DOCKERHUB_USERNAME = data.bitwarden_secret.dockerhub_username.value
    DOCKERHUB_TOKEN    = data.bitwarden_secret.dockerhub_token.value
    # HOMELAB_BOT_APP_ID          = data.bitwarden_secret.homelab_bot_app_id.value
    # HOMELAB_BOT_APP_PRIVATE_KEY = data.bitwarden_secret.homelab_bot_app_private_key.value
    RENOVATE_APP_ID          = data.bitwarden_secret.renovate_app_id.value
    RENOVATE_APP_PRIVATE_KEY = data.bitwarden_secret.renovate_app_private_key.value
  }
  environment_secrets = {
    release = {
      # TODO: add these
      # ARTIFACT_SERVER_HOST
      # ARTIFACT_SERVER_PASSWORD
      # ARTIFACT_SERVER_PATH
      # ARTIFACT_SERVER_USER
      # TAILSCALE_OAUTH_CLIENT_ID
      # TAILSCALE_OAUTH_SECRET
    }
  }
}

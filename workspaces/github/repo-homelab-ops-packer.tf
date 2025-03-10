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
    HOMELAB_BOT_APP_ID          = var.homelab_bot_app_id
    HOMELAB_BOT_APP_PRIVATE_KEY = file(var.homelab_bot_app_private_key)
    # TODO: add these
    # ARTIFACT_SERVER_HOST
    # ARTIFACT_SERVER_PASSWORD
    # ARTIFACT_SERVER_PATH
    # ARTIFACT_SERVER_USER
    # TAILSCALE_OAUTH_CLIENT_ID
    # TAILSCALE_OAUTH_SECRET
  }
}

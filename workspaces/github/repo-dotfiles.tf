module "repo_dotfiles" {
  source = "../../modules/github-repository"
  repository = {
    name        = "dotfiles"
    description = ""
    visibility  = "public"
  }
  actions_allowed = [
    "jdx/mise-action@*",
    "tj-actions/changed-files@*"
  ]
  actions_secrets = {
    DOCKERHUB_USERNAME          = data.bitwarden_secret.dockerhub_username.value
    DOCKERHUB_TOKEN             = data.bitwarden_secret.dockerhub_token.value
    HOMELAB_BOT_APP_ID          = data.bitwarden_secret.homelab_bot_app_id.value
    HOMELAB_BOT_APP_PRIVATE_KEY = data.bitwarden_secret.homelab_bot_app_private_key.value
    RENOVATE_APP_ID             = data.bitwarden_secret.renovate_app_id.value
    RENOVATE_APP_PRIVATE_KEY    = data.bitwarden_secret.renovate_app_private_key.value
  }
  force_push_bypassers = [data.github_user.current.node_id]
}

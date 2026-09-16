module "repo_skills" {
  source = "../../modules/github-repository"
  repository = {
    name        = "skills"
    description = ""
    visibility  = "private"
  }
  actions_allowed = [
    "googleapis/release-please-action@*",
    "jdx/mise-action@*",
    "tj-actions/changed-files@*"
  ]
  actions_secrets = {
    DOCKERHUB_USERNAME          = data.bitwarden_secret.dockerhub_username.value
    DOCKERHUB_TOKEN             = data.bitwarden_secret.dockerhub_token.value
    HOMELAB_BOT_CLIENT_ID       = data.bitwarden_secret.homelab_bot_client_id.value
    HOMELAB_BOT_APP_PRIVATE_KEY = data.bitwarden_secret.homelab_bot_app_private_key.value
    RENOVATE_CLIENT_ID          = data.bitwarden_secret.renovate_client_id.value
    RENOVATE_APP_PRIVATE_KEY    = data.bitwarden_secret.renovate_app_private_key.value
  }
}

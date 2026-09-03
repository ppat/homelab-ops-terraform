module "repo_garage_falsification_harness" {
  source = "../../modules/github-repository"
  repository = {
    name        = "garage-falsification-harness"
    description = ""
    visibility  = "public"
  }
  actions_allowed = [
    "jdx/mise-action@*",
    "tj-actions/changed-files@*"
  ]
  actions_secrets = {
    DOCKERHUB_USERNAME       = data.bitwarden_secret.dockerhub_username.value
    DOCKERHUB_TOKEN          = data.bitwarden_secret.dockerhub_token.value
    RENOVATE_APP_ID          = data.bitwarden_secret.renovate_app_id.value
    RENOVATE_CLIENT_ID       = data.bitwarden_secret.renovate_client_id.value
    RENOVATE_APP_PRIVATE_KEY = data.bitwarden_secret.renovate_app_private_key.value
  }
}

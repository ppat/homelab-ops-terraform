module "repo_self_hosted_renovate" {
  source = "../../modules/github-repository"
  repository = {
    name        = "self-hosted-renovate"
    description = ""
    visibility  = "private"
  }
  environment_secrets = {
    renovate = {
      DOCKERHUB_USERNAME       = data.bitwarden_secret.dockerhub_username.value
      DOCKERHUB_TOKEN          = data.bitwarden_secret.dockerhub_token.value
      RENOVATE_APP_ID          = data.bitwarden_secret.renovate_app_id.value
      RENOVATE_APP_PRIVATE_KEY = data.bitwarden_secret.renovate_app_private_key.value
    }
  }
}

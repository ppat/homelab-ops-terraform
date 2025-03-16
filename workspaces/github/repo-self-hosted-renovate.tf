module "repo_self_hosted_renovate" {
  source = "../../modules/github-repository"
  repository = {
    name        = "self-hosted-renovate"
    description = ""
    visibility  = "private"
  }
  actions_allowed = [
    "renovatebot/github-action@*",
    "tj-actions/changed-files@*"
  ]
  environment_secrets = {
    renovate = {
      DOCKERHUB_USERNAME       = var.dockerhub_username
      DOCKERHUB_TOKEN          = var.dockerhub_token
      RENOVATE_APP_ID          = var.renovate_app_id
      RENOVATE_APP_PRIVATE_KEY = file(var.renovate_app_private_key)
    }
  }
}

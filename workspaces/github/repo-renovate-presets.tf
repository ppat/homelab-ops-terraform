module "repo_renovate_presets" {
  source = "../../modules/github-repository"
  repository = {
    name        = "renovate-presets"
    description = "Presets for Renovate Bot"
    visibility  = "public"
  }
  actions_allowed = [
    "jdx/mise-action@*",
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

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
    renovate = {
      RENOVATE_APP_ID          = var.renovate_app_id
      RENOVATE_APP_PRIVATE_KEY = file(var.renovate_app_private_key)
      DOCKERHUB_USERNAME       = var.dockerhub_username
      DOCKERHUB_TOKEN          = var.dockerhub_token
    }
  }
}

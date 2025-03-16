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
  }
}

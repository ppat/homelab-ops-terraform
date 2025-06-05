module "repo_homelab_ops_ansible" {
  source = "../../modules/github-repository"
  repository = {
    name        = "homelab-ops-ansible"
    description = "Ansible collections for homelab operations"
    visibility  = "public"
  }
  actions_allowed = [
    "jdx/mise-action@*",
    "tj-actions/changed-files@*"
  ]
  environment_secrets = {
    release = {
      ANSIBLE_GALAXY_API_TOKEN = data.bitwarden_secret.ansible_galaxy_api_token.value
      GH_RELEASE_TOKEN         = data.bitwarden_secret.github_release_token.value
    }
    renovate = {
      DOCKERHUB_USERNAME       = data.bitwarden_secret.dockerhub_username.value
      DOCKERHUB_TOKEN          = data.bitwarden_secret.dockerhub_token.value
      RENOVATE_APP_ID          = data.bitwarden_secret.renovate_app_id.value
      RENOVATE_APP_PRIVATE_KEY = data.bitwarden_secret.renovate_app_private_key.value
    }
  }
  topics = [
    "ansible",
    "ansible-collection",
    "homelab"
  ]
}

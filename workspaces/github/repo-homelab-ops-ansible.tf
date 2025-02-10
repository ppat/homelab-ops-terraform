module "repo_homelab_ops_ansible" {
  source = "../../modules/github-repository"
  repository = {
    name        = "homelab-ops-ansible"
    description = "Ansible collections for homelab operations"
    visibility  = "public"
  }
  actions_allowed = [
    "tj-actions/changed-files@*"
  ]
  actions_secrets = {
    SNYK_TOKEN                  = var.snyk_token
    HOMELAB_BOT_APP_ID          = var.homelab_bot_app_id
    HOMELAB_BOT_APP_PRIVATE_KEY = file(var.homelab_bot_app_private_key)
    # TODO: add these
    # ANSIBLE_GALAXY_API_TOKEN
    # FLUX_REPO_READER_SSH_KEY
    # GH_RELEASE_TOKEN
  }
  topics = [
    "ansible",
    "ansible-collection",
    "homelab"
  ]
}

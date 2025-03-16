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
      ANSIBLE_GALAXY_API_TOKEN = var.ansible_galaxy_api_token
      GH_RELEASE_TOKEN         = var.gh_release_token
    }
  }
  topics = [
    "ansible",
    "ansible-collection",
    "homelab"
  ]
}

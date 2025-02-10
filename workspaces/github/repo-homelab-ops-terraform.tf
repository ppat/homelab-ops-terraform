module "repo_homelab_ops_terraform" {
  source = "../../modules/github-repository"
  repository = {
    name        = "homelab-ops-terraform"
    description = ""
    visibility  = "public"
  }
  actions_allowed = [
    "tj-actions/changed-files@*"
  ]
  actions_secrets = {
    SNYK_TOKEN                  = var.snyk_token
    HOMELAB_BOT_APP_ID          = var.homelab_bot_app_id
    HOMELAB_BOT_APP_PRIVATE_KEY = file(var.homelab_bot_app_private_key)
  }
  #   required_status_checks = [
  #     "Snyk Security Check",
  #     "terraform-fmt",
  #     "terraform-validate"
  #   ]
}

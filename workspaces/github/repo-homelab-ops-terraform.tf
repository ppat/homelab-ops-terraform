module "repo_homelab_ops_terraform" {
  source = "../../modules/github-repository"
  repository = {
    name        = "homelab-ops-terraform"
    description = ""
    visibility  = "public"
  }
  actions_allowed = [
    "aquasecurity/trivy-action@*",
    "bridgecrewio/checkov-action@*",
    "github/codeql-action/upload-sarif@*",
    "jdx/mise-action@*",
    "tj-actions/changed-files@*"
  ]
  # force_push_bypassers = [data.github_user.current.node_id]
  #   required_status_checks = [
  #     "Snyk Security Check",
  #     "terraform-fmt",
  #     "terraform-validate"
  #   ]
}

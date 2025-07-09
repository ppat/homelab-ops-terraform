resource "github_branch_protection" "main" {
  repository_id                   = github_repository.repository.node_id
  pattern                         = "main"
  allows_deletions                = false
  allows_force_pushes             = false
  enforce_admins                  = true
  force_push_bypassers            = var.force_push_bypassers
  require_conversation_resolution = false
  required_linear_history         = true
  require_signed_commits          = var.require_signed_commits

  required_status_checks {
    strict   = true
    contexts = var.required_status_checks
  }
}

resource "harbor_retention_policy" "retention_policy" {
  scope    = harbor_project.project.id
  schedule = "Daily"

  rule {
    n_days_since_last_pull = var.retention_policy.n_days_since_last_pull
    repo_matching          = "**"
    tag_matching           = "**"
    untagged_artifacts     = true
  }
  rule {
    most_recently_pulled = var.retention_policy.most_recently_pulled
    repo_matching        = "**"
    tag_matching         = "**"
    untagged_artifacts   = true
  }
  rule {
    always_retain      = true
    repo_matching      = "**"
    tag_matching       = "latest"
    untagged_artifacts = false
  }
}

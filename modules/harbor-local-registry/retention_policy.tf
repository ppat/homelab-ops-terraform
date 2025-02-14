locals {
  always_retain_tags = length(var.retention_policy.always_retain_tags) > 1 ? format("{%s}", join(",", var.retention_policy.always_retain_tags)) : var.retention_policy.always_retain_tags[0]
}

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
    n_days_since_last_push = var.retention_policy.n_days_since_last_push
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
    tag_matching       = local.always_retain_tags
    untagged_artifacts = false
  }
}

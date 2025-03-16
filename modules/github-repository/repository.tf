resource "github_repository" "repository" {
  name        = var.repository.name
  description = var.repository.description
  visibility  = var.repository.visibility

  has_discussions = true
  has_issues      = true
  has_projects    = false
  has_wiki        = false

  allow_merge_commit  = false
  allow_rebase_merge  = false
  allow_squash_merge  = true
  allow_update_branch = true

  auto_init              = false
  homepage_url           = var.homepage_url
  delete_branch_on_merge = true
  topics                 = var.topics

  dynamic "security_and_analysis" {
    for_each = var.repository.visibility == "public" ? [1] : []
    content {
      secret_scanning {
        status = "enabled"
      }
      secret_scanning_push_protection {
        status = "enabled"
      }
    }
  }
}

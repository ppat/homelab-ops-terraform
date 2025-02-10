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
  delete_branch_on_merge = true
  topics                 = var.topics

  security_and_analysis {
    secret_scanning {
      status = var.repository.visibility == "public" ? "enabled" : "disabled"
    }
    secret_scanning_push_protection {
      status = var.repository.visibility == "public" ? "enabled" : "disabled"
    }
  }
}

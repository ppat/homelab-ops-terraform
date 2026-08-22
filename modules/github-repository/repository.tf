resource "github_repository" "repository" {
  name        = var.repository.name
  description = var.repository.description
  visibility  = var.repository.visibility

  has_discussions = var.repository.visibility == "public"
  has_issues      = true
  has_projects    = false
  has_wiki        = false

  # Squash-only is the invariant: no merge commits, no rebase merges, ever.
  #
  # The three settings below were GitHub defaults rather than choices until now.
  # They are pinned here because what they resolve to is not obvious and matters:
  #
  #   squash_merge_commit_title/message -- GitHub accepts only four combinations
  #   (PR_TITLE+PR_BODY, PR_TITLE+BLANK, PR_TITLE+COMMIT_MESSAGES,
  #   COMMIT_OR_PR_TITLE+COMMIT_MESSAGES; the other two are rejected 422). Measured
  #   on a throwaway repo across all four and both PR shapes, this is the only one
  #   that serves every actor: a one-commit PR lands that commit verbatim (what
  #   Renovate and release-please produce -- their PR titles are byte-identical to
  #   their single commit's subject), and a multi-commit PR lands the PR title with
  #   the commit messages as bullets. PR_BODY would land Renovate's dependency
  #   table, checkboxes and HTML comments verbatim into the commit body -- measured
  #   at 991 to 57,997 characters. BLANK would throw away every commit body.
  #
  #   allow_auto_merge -- false deliberately. GitHub-native auto-merge waits on
  #   REQUIRED checks only and merges over everything else; measured, a PR with a
  #   failing non-required check auto-merged as soon as the required one passed.
  #   The path-filtered chainsaw suites cannot be required (a workflow that never
  #   triggers never reports, and the context hangs forever), so enabling this
  #   would let those merge red: 15 of 103 sampled Renovate PRs had a red
  #   non-required check while every required one was green. With it false,
  #   Renovate falls back to its own merge path, which gates on ALL checks.
  allow_auto_merge            = false
  allow_merge_commit          = false
  allow_rebase_merge          = false
  allow_squash_merge          = true
  allow_update_branch         = true
  squash_merge_commit_title   = "COMMIT_OR_PR_TITLE"
  squash_merge_commit_message = "COMMIT_MESSAGES"

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

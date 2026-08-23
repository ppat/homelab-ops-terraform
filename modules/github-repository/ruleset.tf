# WHY A RULESET ON TOP OF CLASSIC BRANCH PROTECTION
#
# Purpose: give agent work a server-side boundary. Agents authenticate as a GitHub App
# (a distinct actor), push branches and open PRs freely, but cannot land anything on
# main; the maintainer and the merge automation are in the bypass list. Classic branch
# protection cannot express this because a PAT under the owner's account is the same
# actor as the owner.
#
# How the two systems compose (the evidence that established these facts is in the
# pull request that introduced this file):
#
#   a. Rulesets and classic branch protection are additive; the most restrictive
#      answer wins. Adding this ruleset changes NOTHING in branch-protection.tf and
#      none of its behavior -- required contexts, enforce_admins, signatures and
#      linear history all keep operating unchanged.
#   b. A ruleset bypass exempts its holder from THIS RULESET ONLY, never from branch
#      protection: required contexts and enforce_admins still bind bypass holders. A
#      bypass entry is not an admin override of the merge gate, and a required context
#      that is never reported still cannot be clicked past (see the RECOVERY note in
#      workspaces/github/repo-homelab-ops-kubernetes-apps.tf).
#   c. required_approving_review_count = 0 makes the pull_request rule decorative: any
#      actor with contents write can merge. An actor cannot approve its own PR, so
#      >= 1 is what actually stops a self-authored PR being self-merged.
#   d. Residual, stated so it is not rediscovered as a surprise: an actor with
#      pull-requests write can approve SOMEONE ELSE'S PR and (with contents write)
#      merge it. The approval requirement only binds self-authored PRs. The stricter
#      alternative -- an `update` rule, under which only bypass actors can update the
#      branch at all, by push or by merge -- closes that but gates every future
#      main-updating actor on the bypass list; deliberately not chosen here.
#
# The repository-admin bypass entry is hardcoded below -- its presence, actor id and
# type are fixed; only its bypass_mode is configurable
# (var.main_ruleset_admin_bypass_mode), because the mode is policy while the entry's
# presence is the safety invariant. The presence is not a preference: on a single-maintainer repository with enforce_admins true, a ruleset
# requiring an approval and carrying no admin bypass could never be satisfied by
# anyone -- every pull request into the branch would stay unmergeable, permanently.
# Making the entry structural means no caller can produce that configuration. Base repository role ids (maintain 2, write 4,
# admin 5) are part of GitHub's global schema: the API resolves the bare integers to
# role names with no per-repository context, and custom org roles occupy a separate
# id range. var.main_ruleset_additional_bypass_actors carries only the extra actors
# (merge-automation Apps).
#
# Merge methods are not encoded here: repository.tf already pins squash-only at the
# repository level, and encoding the same judgment twice is drift risk.
resource "github_repository_ruleset" "main" {
  count = var.main_ruleset_enabled ? 1 : 0

  name        = "require-pull-request-on-main"
  repository  = github_repository.repository.name
  target      = "branch"
  enforcement = "active"

  conditions {
    ref_name {
      include = ["~DEFAULT_BRANCH"]
      exclude = []
    }
  }

  # The guard that keeps the ruleset satisfiable (see the header comment): the
  # entry's presence, actor and type are fixed -- only its mode is configurable.
  #
  # Why the mode defaults to "pull_request", not "always": "always" exempts the
  # holder on every path, including a direct push to the default branch -- and this
  # ruleset is the control that actually rejects such a push (measured: an unsigned
  # commit pushed directly to main was refused by this ruleset alone, with no
  # signature violation raised). "pull_request" confines the bypass to merging pull
  # requests, so an accidental direct push is refused while the admin can still
  # merge any PR without an approval -- which is all this guard requires, and both
  # accepted modes cover PR merges, so neither can leave pull requests unmergeable.
  bypass_actors {
    actor_id    = 5
    actor_type  = "RepositoryRole"
    bypass_mode = var.main_ruleset_admin_bypass_mode
  }

  dynamic "bypass_actors" {
    for_each = var.main_ruleset_additional_bypass_actors
    content {
      actor_id    = bypass_actors.value.actor_id
      actor_type  = bypass_actors.value.actor_type
      bypass_mode = bypass_actors.value.bypass_mode
    }
  }

  rules {
    pull_request {
      required_approving_review_count   = var.main_ruleset_required_approving_review_count
      dismiss_stale_reviews_on_push     = false
      require_code_owner_review         = false
      require_last_push_approval        = false
      required_review_thread_resolution = false
    }
  }
}

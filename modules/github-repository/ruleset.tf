# WHY A RULESET ON TOP OF CLASSIC BRANCH PROTECTION (measured, not documented)
#
# Purpose: give agent work a server-side boundary. Agents authenticate as a GitHub App
# (a distinct actor), push branches and open PRs freely, but cannot land anything on
# main; the humans and the merge automation are in the bypass list. Classic branch
# protection cannot express this because a PAT under the owner's account is the same
# actor as the owner.
#
# Both systems were measured coexisting on a throwaway repo (ppat/bp-semantics-probe,
# 2026-08-23; full write-up: .session-notes/apps-taxonomy/61-agent-identity.md) with a
# production-replica protection object (required check, enforce_admins, linear history,
# signatures) plus this ruleset:
#
#   a. They are additive; the most restrictive answer wins. A push that classic
#      protection allowed (required check green) was rejected by the ruleset's PR
#      requirement, and a PR merge the ruleset allowed stayed blocked on a red
#      required context. Adding this ruleset changes NOTHING in branch-protection.tf
#      and none of its behavior.
#   b. A ruleset bypass exempts its holder from THIS RULESET ONLY. Measured: with the
#      admin role in this bypass list, a direct push of a commit lacking the required
#      context was still rejected -- "Required status check ... is expected" -- i.e.
#      required contexts and enforce_admins from classic protection still bind bypass
#      holders. Bypass here is not an admin override of the merge gate, and a wedged
#      required context still cannot be clicked past (see the RECOVERY note in
#      workspaces/github/repo-homelab-ops-kubernetes-apps.tf).
#   c. required_approving_review_count = 0 makes the pull_request rule decorative:
#      the merge gate read "mergeable" for a plain write actor. At >= 1 it read
#      BLOCKED / REVIEW_REQUIRED. An actor cannot approve its own PR, so >= 1 is what
#      actually stops a self-authored PR being self-merged.
#   d. Residual, stated so it is not rediscovered as a surprise: an actor with
#      pull_requests:write can approve SOMEONE ELSE'S PR and (with contents:write)
#      merge it. The approval requirement only binds self-authored PRs. The stricter
#      alternative -- an `update` rule, which blocked even a green admin push and read
#      BLOCKED on every non-bypass PR merge (both measured) -- closes that but gates
#      every future actor on the bypass list; deliberately not chosen here.
#
# Merge methods are not encoded here: repository.tf already pins squash-only at the
# repository level, and encoding the same judgment twice is drift risk (same reasoning
# as the MCP allowlist decision in apps#3826's review).
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

  dynamic "bypass_actors" {
    for_each = var.main_ruleset_bypass_actors
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

  lifecycle {
    # THE ORDERING TRAP. With an empty bypass list this rule applies to the repository
    # owner too: the owner is the only human, nobody can approve their PRs, and
    # enforce_admins is true on the classic layer, so an empty bypass list wedges the
    # repository completely -- no PR can ever be merged again except by deleting the
    # ruleset. Refuse the configuration instead of applying it.
    precondition {
      condition     = !var.main_ruleset_enabled || length(var.main_ruleset_bypass_actors) > 0
      error_message = "main_ruleset_enabled requires a non-empty main_ruleset_bypass_actors: with no bypass the sole maintainer can never satisfy the approval requirement and the repository wedges."
    }
  }
}

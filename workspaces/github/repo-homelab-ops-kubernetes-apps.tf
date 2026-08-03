module "repo_homelab_ops_kubernetes_apps" {
  source = "../../modules/github-repository"
  repository = {
    name        = "homelab-ops-kubernetes-apps"
    description = "Kubernetes Application manifests grouped by subsystem for Homelab"
    visibility  = "public"
  }
  actions_allowed = [
    "docker://ghcr.io/allenporter/flux-local:*",
    "googleapis/release-please-action@*",
    "jdx/mise-action@*",
    "tj-actions/changed-files@*"
  ]
  # #3416 and #3417 are both merged and confirmed green on main (kubernetes-manifests
  # re-verified directly via workflow_dispatch against main's tip; detect-changes and
  # pre-commit confirmed in the same run). Safe to apply.
  #
  # This list is deliberately NOT every job in lint.yaml. A GitHub Actions job's check-run
  # *name* is only stable across every PR if either (a) it has no job-level `if:` at all,
  # or (b) its `if:` is unconditionally true for every `pull_request` event. Two distinct
  # ways a job can fail that test, both confirmed against real runs on this repo:
  #
  #   1. Workflow-level `paths:` filters (diff-changes.yaml's `diff` job, and every
  #      chainsaw `test-*.yaml` workflow) mean the workflow never triggers at all for a
  #      PR that doesn't touch matching paths - zero check runs posted, so a required
  #      check on any of their job names gets stuck "Expected" forever on unrelated PRs.
  #      diff-changes.yaml also stacks a *dynamic* module x resource matrix on top (post
  #      #3515), making individual `diff (<module>, <resource>)` names even less stable.
  #
  #   2. Job-level `if:` gating a *reusable workflow call* (lint.yaml's `github-actions`,
  #      `markdown`, `renovate-config-check`, `shellcheck`, `yaml` jobs - all gated on
  #      `fromJSON(needs.detect-changes.outputs.results).<bucket>_any_changed`) changes
  #      the check-run *name itself* depending on whether the job actually invoked the
  #      reusable workflow: it reports as bare `shellcheck` when skipped, but
  #      `shellcheck / shellcheck` when it actually runs - two genuinely different
  #      context strings from GitHub's point of view, confirmed via the raw Checks API
  #      (not just the CLI display) against a real PR. Classic branch protection has no
  #      OR-semantics, so requiring both strings doesn't help - it'd just permanently wait
  #      on whichever one didn't fire. Fixing this needs an always-run gate job in
  #      lint.yaml (aggregating `needs.*.result` with `if: always()`) before those five
  #      can be safely required - not something this Terraform list alone can solve.
  #
  # The three below are unaffected by either failure mode: `kubernetes-manifests` has no
  # reusable-workflow call at all (inline job, name never has a slash); `detect-changes`/
  # `pre-commit` have no job-level `if:` at all.
  #
  # `commit-messages / commit-messages` is ALSO name-stable (its only gate is
  # `event_name == 'pull_request'`, true for every real PR) but deliberately left out
  # anyway: Renovate-authored commits sometimes fail commitlint, and making this required
  # would block those PRs - including automerge - on a lint failure in a commit message
  # neither this repo nor Renovate's own config fully controls. Revisit only if that
  # gets fixed at the source (Renovate commit-message template / commitlint config).
  required_status_checks = [
    "kubernetes-manifests",
    "detect-changes / detect-changed-files",
    "pre-commit / pre-commit"
  ]
  actions_secrets = {
    DOCKERHUB_USERNAME          = data.bitwarden_secret.dockerhub_username.value
    DOCKERHUB_TOKEN             = data.bitwarden_secret.dockerhub_token.value
    HOMELAB_BOT_APP_ID          = data.bitwarden_secret.homelab_bot_app_id.value
    HOMELAB_BOT_APP_PRIVATE_KEY = data.bitwarden_secret.homelab_bot_app_private_key.value
    RENOVATE_APP_ID             = data.bitwarden_secret.renovate_app_id.value
    RENOVATE_APP_PRIVATE_KEY    = data.bitwarden_secret.renovate_app_private_key.value
  }
}

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
  # HOW GITHUB DECIDES A REQUIRED CONTEXT IS SATISFIED (measured, not documented)
  #
  # The matching key is the check-run *name*, resolved against the check suites of the
  # pull_request event only. Four properties drive everything below; each was measured on
  # a throwaway repo and cross-checked against real runs here. Full write-up and evidence:
  # .session-notes/apps-taxonomy/55-branch-protection.md.
  #
  #   a. A workflow that never triggers posts nothing, and an unreported context stays
  #      "Expected" forever. Every `paths:`-filtered workflow here (diff-changes.yaml, all
  #      eighteen test-*.yaml) is therefore unrequireable, permanently.
  #   b. A job skipped by an `if:` DOES report, with conclusion "skipped" -- and skipped
  #      SATISFIES a required context. So an `if:` does not make a check fail; it makes it
  #      silently pass. What breaks is the NAME: a job that calls a reusable workflow
  #      reports `shellcheck` when skipped and `shellcheck / shellcheck` when it runs. Two
  #      different strings, and classic protection has no OR. That rules out lint.yaml's
  #      github-actions/markdown/renovate-config-check/shellcheck/yaml/zizmor jobs.
  #   c. The same name reported by TWO workflows must be non-failing in BOTH. Live here:
  #      lint.yaml and diff-changes.yaml each define a job id `detect-changes` calling the
  #      same reusable workflow, so `detect-changes / detect-changed-files` is emitted
  #      twice on 165 of 300 sampled PRs. The context below therefore also gates
  #      diff-changes.yaml's change detection. Nobody chose that; it is currently
  #      harmless and arguably useful, but rename either job id and this list changes
  #      meaning without changing text.
  #   d. Two check suites of the SAME workflow resolve to the newest. That is why a
  #      re-run, a reopen, or a PR-title edit clears an earlier failure.
  #
  # THE FOUR CONTEXTS BELOW
  #
  # kubernetes-manifests -- inline job, no `if:`, no slash in the name, always fires. Note
  #   it has `needs: [detect-changes]`, so a detect-changes failure makes it report
  #   "skipped" and pass vacuously; that is covered only because detect-changes is itself
  #   required.
  # detect-changes / detect-changed-files -- no job-level `if:`; see (c) above.
  # pre-commit / pre-commit -- no `if:`, no `needs:`.
  # commit-taxonomy -- the best-shaped candidate in the repository: inline (no slash), no
  #   `if:` (cannot go vacuous), no `needs:`, in a workflow with no `paths:` filter, unique
  #   name, 14s. It gates the one thing nothing else sees: that the Renovate/release-please
  #   config CANNOT compile a header commitlint would reject. Two costs, stated: its verdict
  #   is a function of repo state rather than the PR's diff, so when it goes red it goes red
  #   on every open PR at once; and it fetches pinned presets over the network
  #   (ppat/homelab-ops-kubernetes-apps#3818 adds retry + timeout to that call and must land
  #   first).
  #
  # DELIBERATELY NOT REQUIRED
  #
  # commit-messages / commit-messages -- mechanically safe (302/302 sampled PRs report the
  #   slashed name; the bare form never occurs on a pull_request event). Held back on
  #   policy: it was dropped in #280 because Renovate commits sometimes fail commitlint,
  #   and the emission-closure check is supposed to retire that objection -- but it is a
  #   MODEL of the emitter, and the conformance check against the real Renovate CLI
  #   (apps#3797) is still open. Require it after that lands, not before.
  # pr-title -- ppat/homelab-ops-kubernetes-apps#3819 adds a job that lints the PR title,
  #   which is the subject that lands for every multi-commit PR and which nothing has ever
  #   checked. Same shape as commit-taxonomy and safe to require, but only once it has a
  #   track record on real PRs. That is the next entry in this list, not this change.
  #
  # RECOVERY, BECAUSE THERE IS NONE IN-BAND
  #
  # enforce_admins is true, and while a ruleset with a bypass list now sits on main (see
  # main_ruleset_* below), a ruleset bypass exempts its holder from the ruleset only -- it
  # does not clear a wedged required context, so a wedged context still cannot be clicked
  # past. workflow_dispatch does NOT help: check runs
  # from a dispatch suite land on the head SHA but are not in the pull_request rollup the
  # gate reads (measured). The remedy for a wedge is to remove the context here, apply,
  # merge, restore. Keep that cost in mind before adding a fifth entry.
  required_status_checks = [
    "kubernetes-manifests",
    "detect-changes / detect-changed-files",
    "pre-commit / pre-commit",
    "commit-taxonomy"
  ]
  # strict stays false. Measured: strict is entirely inert while contexts is empty, so the
  # module default did nothing until #280 gave this repo a non-empty list on 2026-08-03 --
  # which means #280 switched on the up-to-date requirement for the first time, and #288
  # turned it off nine days later. The contexts were never the problem (they report on
  # 300/300 sampled PRs and essentially never fail); strict was. With 4-39 merges/day into
  # main, every merge flips every open PR to "behind" and forces a full CI re-run.
  required_status_checks_strict = false
  # AGENT IDENTITY BOUNDARY (see modules/github-repository/ruleset.tf for how the
  # ruleset composes with classic branch protection, and for the residual it accepts)
  #
  # Agents authenticate as their own GitHub App. The App pushes branches and opens PRs;
  # this ruleset is what stops it landing anything on main: 1 required approval, and an
  # actor cannot approve its own PR. The module hardcodes the repository-admin bypass
  # (the maintainer -- also the guard that makes a wedge impossible); listed here are
  # the additional actors that legitimately update main today:
  #
  #   homelab-bot (Integration) -- release-please's PR pushes and the release-sweep's
  #     squash merges (apps#3826); without bypass the sweep cannot merge unapproved
  #     release PRs and tagging stops.
  #   renovate app (Integration) -- Renovate merges its own automerge-eligible PRs via
  #     API (platformAutomerge is inert with allow_auto_merge=false); without bypass
  #     automerge silently stops and PRs pile up.
  #
  # NOTE: until agent pods stop authenticating with the maintainer's PAT, agents share
  # the admin bypass and the ruleset protects nothing (it is safe either way -- the
  # hardcoded admin bypass means it can never wedge the repo). The boundary becomes
  # real when the dotfiles change lands.
  #
  # bypass_mode is "pull_request" for both: "always" would exempt these Apps on every
  # path, including a direct push to main; "pull_request" confines the bypass to
  # merging pull requests, which is the only way either bot legitimately updates main.
  #
  # UNVERIFIED, AND THE FAILURE IS SILENT: both bots merge via the API, and whether
  # "pull_request" mode covers an API-driven merge has not been exercised. If it does
  # not, Renovate automerge and the release sweep stop landing PRs, and the symptom
  # looks exactly like "nothing was eligible this run". If bot merges stop, flip these
  # two entries back to "always" -- that is the whole remedy, and it needs no module
  # change (bypass_mode is per-entry; main_ruleset_admin_bypass_mode below is the
  # admin's own dial and stays put -- the human is not merging via the API).
  #
  # For Integration actors, actor_id is the GitHub App id -- after any change here,
  # verify the repo's rules page renders the App names in the bypass list.
  main_ruleset_enabled           = true
  main_ruleset_admin_bypass_mode = "pull_request"
  main_ruleset_additional_bypass_actors = [
    { actor_id = tonumber(data.bitwarden_secret.homelab_bot_app_id.value), actor_type = "Integration", bypass_mode = "pull_request" },
    { actor_id = tonumber(data.bitwarden_secret.renovate_app_id.value), actor_type = "Integration", bypass_mode = "pull_request" },
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

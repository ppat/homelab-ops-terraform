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
  # DO NOT APPLY until ppat/homelab-ops-kubernetes-apps#3416 and #3417 are both fixed
  # AND confirmed reliably green on that repo's `main` - see PR description for why.
  #
  # Only `kubernetes-manifests` is listed: it's a single, fixed-name job with no
  # matrix, so it always reports a check for every PR. The `diff-changes.yaml`
  # workflow's `diff` job (the #3417 checks) uses a *dynamic* `module x resource`
  # matrix derived from which modules a given PR touches - e.g. `diff (infra-database,
  # helmrelease)` only exists on PRs that touch infra-database. Naming any of those
  # matrix entries here would make GitHub wait forever ("Expected") on PRs that never
  # produce that specific combination, permanently blocking their merge. There's no
  # aggregator/gate job over the diff matrix to point at instead (verified by reading
  # .github/workflows/diff-changes.yaml directly) - adding one is a separate follow-up
  # if the diff checks should ever become required.
  required_status_checks = [
    "kubernetes-manifests"
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

module "repo_homelab_ops_policies" {
  source = "../../modules/github-repository"
  repository = {
    name        = "homelab-ops-policies"
    description = ""
    visibility  = "public"
  }
  actions_allowed = [
    "docker://ghcr.io/allenporter/flux-local:*",
    "jdx/mise-action@*",
    "tj-actions/changed-files@*"
  ]
  # Full derivation of how GitHub resolves a required context, and the failure mode of
  # getting one wrong, is in repo-homelab-ops-kubernetes-apps.tf's comment -- not repeated
  # here. All three contexts below carry no `if:`, no `needs:`, and no `paths:` filter on
  # their workflow, so none can go permanently unrequireable or silently vacuous.
  #
  # commit-messages / commit-messages -- a `uses:` call into a reusable workflow, so the
  #   name resolves as `<caller job id> / <reusable job id>`.
  # commit-taxonomy, pr-title -- inline jobs (a script run directly, not a
  #   reusable-workflow call), so each name is bare, with no slash.
  #
  # A context that never once reports leaves every PR permanently unmergeable
  # (enforce_admins = true blocks even the repo owner, and there is no in-band recovery --
  # only another apply removing the context). Before adding another entry here, reproduce
  # that same evidence for it: the exact string from a real check-runs response, not the
  # workflow file, and confirmation it is not path-gated.
  required_status_checks = [
    "commit-messages / commit-messages",
    "commit-taxonomy",
    "pr-title"
  ]
  actions_secrets = {
    DOCKERHUB_USERNAME          = data.bitwarden_secret.dockerhub_username.value
    DOCKERHUB_TOKEN             = data.bitwarden_secret.dockerhub_token.value
    HOMELAB_BOT_APP_ID          = data.bitwarden_secret.homelab_bot_app_id.value
    HOMELAB_BOT_CLIENT_ID       = data.bitwarden_secret.homelab_bot_client_id.value
    HOMELAB_BOT_APP_PRIVATE_KEY = data.bitwarden_secret.homelab_bot_app_private_key.value
    RENOVATE_APP_ID             = data.bitwarden_secret.renovate_app_id.value
    RENOVATE_CLIENT_ID          = data.bitwarden_secret.renovate_client_id.value
    RENOVATE_APP_PRIVATE_KEY    = data.bitwarden_secret.renovate_app_private_key.value
  }
}

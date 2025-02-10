module "repo_homelab_ops_kubernetes_apps" {
  source = "../../modules/github-repository"
  repository = {
    name        = "homelab-ops-kubernetes-apps"
    description = "Kubernetes Application manifests grouped by subsystem for Homelab"
    visibility  = "public"
  }
  actions_allowed = [
    "allenporter/flux-local/action/diff@*",
    "fluxcd/flux2/action@*",
    "fluxcd/pkg/actions/kubectl@*",
    "googleapis/release-please-action@*",
    "helm/kind-action@*",
    "mshick/add-pr-comment@*",
    "tj-actions/changed-files@*"
  ]
  actions_secrets = {
    SNYK_TOKEN                  = var.snyk_token
    HOMELAB_BOT_APP_ID          = var.homelab_bot_app_id
    HOMELAB_BOT_APP_PRIVATE_KEY = file(var.homelab_bot_app_private_key)
  }
}

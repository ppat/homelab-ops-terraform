module "repo_renovate_presets" {
  source = "../../modules/github-repository"
  repository = {
    name        = "renovate-presets"
    description = "Presets for Renovate Bot"
    visibility  = "public"
  }
  actions_allowed = [
    "tj-actions/changed-files@*"
  ]
}

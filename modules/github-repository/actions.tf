resource "github_actions_repository_permissions" "actions_permissions" {
  repository      = github_repository.repository.name
  allowed_actions = "selected"
  enabled         = true

  allowed_actions_config {
    github_owned_allowed = true
    patterns_allowed     = var.actions_allowed
    verified_allowed     = true
  }
}

resource "github_actions_secret" "secret" {
  for_each        = var.actions_secrets
  repository      = github_repository.repository.name
  secret_name     = replace(upper(each.key), "-", "_")
  plaintext_value = each.value
}

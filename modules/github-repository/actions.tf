resource "github_actions_repository_permissions" "actions_permissions" {
  repository      = github_repository.repository.name
  allowed_actions = var.repository.visibility == "public" ? "selected" : "all"
  enabled         = true

  dynamic "allowed_actions_config" {
    for_each = var.repository.visibility == "public" ? [1] : []
    content {
      github_owned_allowed = true
      patterns_allowed     = var.actions_allowed
      verified_allowed     = true
    }
  }
}

resource "github_actions_secret" "secret" {
  for_each        = var.actions_secrets
  repository      = github_repository.repository.name
  secret_name     = replace(upper(each.key), "-", "_")
  plaintext_value = each.value
}

resource "github_actions_variable" "variable" {
  for_each      = var.actions_variables
  repository    = github_repository.repository.name
  variable_name = replace(upper(each.key), "-", "_")
  value         = each.value
}

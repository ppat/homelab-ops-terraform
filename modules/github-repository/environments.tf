locals {
  flattened_secrets = flatten([
    for env_name, secrets in var.environment_secrets : [
      for secret_name, secret_value in secrets : {
        env_name     = env_name
        secret_name  = secret_name
        secret_value = secret_value
      }
    ]
  ])

  secrets_map = {
    for secret in local.flattened_secrets :
    "${secret.env_name}.${secret.secret_name}" => secret
  }
}

resource "github_repository_environment" "environments" {
  for_each    = var.environment_secrets
  environment = each.key
  repository  = github_repository.repository.name
}

resource "github_actions_environment_secret" "environment_secrets" {
  for_each        = local.secrets_map
  environment     = each.value.env_name
  repository      = github_repository.repository.name
  secret_name     = replace(upper(each.value.secret_name), "-", "_")
  plaintext_value = each.value.secret_value

  depends_on = [
    github_repository_environment.environments
  ]
}

output "application" {
  value = authentik_application.application
}

output "oauth2_provider" {
  value = authentik_provider_oauth2.provider
}

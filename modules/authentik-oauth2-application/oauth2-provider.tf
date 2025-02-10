resource "authentik_provider_oauth2" "provider" {
  name                  = "${var.name}-oidc"
  client_id             = var.client_id
  client_type           = "confidential"
  allowed_redirect_uris = var.redirect_uris
  signing_key           = var.signing_key_id
  property_mappings     = sort(var.property_mappings)

  authentication_flow = var.flows.authentication
  authorization_flow  = var.flows.authorization
  invalidation_flow   = var.flows.invalidation

  access_code_validity   = var.validity.access_code
  access_token_validity  = var.validity.access_token
  refresh_token_validity = var.validity.refresh_token
}

resource "bitwarden_secret" "oidc_clientid" {
  depends_on = [authentik_provider_oauth2.provider]
  key        = "oidc_${replace(var.name, "-", "_")}_clientid"
  value      = authentik_provider_oauth2.provider.client_id
  project_id = var.bitwarden_project_id
  note       = "${var.name}'s oidc clientid"
}

resource "bitwarden_secret" "bucket_owner_secretkey" {
  depends_on = [authentik_provider_oauth2.provider]
  key        = "oidc_${replace(var.name, "-", "_")}_clientsecret"
  value      = authentik_provider_oauth2.provider.client_secret
  project_id = var.bitwarden_project_id
  note       = "${var.name}'s oidc clientsecret"
}

data "authentik_flow" "default_provider_authorization_implicit_consent" {
  slug = "default-provider-authorization-implicit-consent"
}

# tflint-ignore: terraform_unused_declarations
data "authentik_flow" "default_provider_authorization_explicit_consent" {
  slug = "default-provider-authorization-explicit-consent"
}

data "authentik_flow" "default_provider_invalidation_flow" {
  slug = "default-provider-invalidation-flow"
}

data "authentik_certificate_key_pair" "signing_key_pair" {
  name = var.signing_key
}

data "authentik_property_mapping_provider_scope" "default" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-email",
    "goauthentik.io/providers/oauth2/scope-openid",
    "goauthentik.io/providers/oauth2/scope-profile"
  ]
}

data "authentik_property_mapping_provider_scope" "offline_access" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-offline_access"
  ]
}

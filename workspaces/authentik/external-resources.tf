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

data "authentik_group" "homelab_admins" {
  name = "homelab-admins"
}

data "authentik_group" "homelab_users" {
  name = "homelab-users"
}

data "authentik_group" "media_admins" {
  name = "media-admins"
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

data "authentik_property_mapping_provider_scope" "entitlements" {
  managed_list = [
    "goauthentik.io/providers/oauth2/scope-entitlements"
  ]
}

data "authentik_property_mapping_provider_scope" "proxy" {
  managed_list = [
    "goauthentik.io/providers/proxy/scope-proxy"
  ]
}

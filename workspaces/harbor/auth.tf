resource "harbor_config_auth" "oidc" {
  auth_mode         = "oidc_auth"
  primary_auth_mode = false

  oidc_admin_group   = "homelab-admins"
  oidc_auto_onboard  = true
  oidc_name          = "authentik"
  oidc_endpoint      = "https://auth.homelab.${data.bitwarden_secret.dns_zone.value}/application/o/harbor/"
  oidc_client_id     = data.bitwarden_secret.harbor_oidc_clientid.value
  oidc_client_secret = data.bitwarden_secret.harbor_oidc_clientsecret.value
  oidc_groups_claim  = "groups"
  oidc_group_filter  = "homelab-users"
  oidc_scope         = "openid,offline_access,email,profile"
  oidc_user_claim    = "preferred_username"
  oidc_verify_cert   = true
}

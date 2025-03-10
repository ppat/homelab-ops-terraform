module "oauth2_openwebui" {
  source               = "../../modules/authentik-oauth2-application"
  name                 = "openwebui"
  bitwarden_project_id = var.bitwarden_project_id
  client_id            = var.clientid_openwebui
  flows                = local.default_flows
  groups               = [data.authentik_group.homelab_admins.id, data.authentik_group.homelab_users.id]
  launch_url           = "https://openwebui.homelab.${var.dns_zone}"
  signing_key_id       = data.authentik_certificate_key_pair.signing_key_pair.id

  property_mappings = concat(
    data.authentik_property_mapping_provider_scope.default.ids
  )
  redirect_uris = [{
    matching_mode = "strict"
    url           = "https://openwebui.homelab.${var.dns_zone}/oauth/oidc/callback"
  }]
}

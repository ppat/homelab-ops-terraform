module "oauth2_coder" {
  source               = "../../modules/authentik-oauth2-application"
  name                 = "coder"
  bitwarden_project_id = var.bitwarden_project_id
  client_id            = var.clientid_coder
  flows                = local.default_flows
  groups               = [data.authentik_group.homelab_admins.id, data.authentik_group.homelab_users.id]
  # icon_url             = "https://s3.homelab.${data.bitwarden_secret.dns_zone.value}/homelab-authentik-media/media/public/application-icons/coder.svg"
  launch_url     = "https://coder.homelab.${data.bitwarden_secret.dns_zone.value}"
  signing_key_id = data.authentik_certificate_key_pair.signing_key_pair.id

  property_mappings = concat(
    data.authentik_property_mapping_provider_scope.default.ids,
    data.authentik_property_mapping_provider_scope.offline_access.ids
  )
  redirect_uris = [{
    matching_mode = "strict"
    url           = "https://coder.homelab.${data.bitwarden_secret.dns_zone.value}/api/v2/users/oidc/callback"
  }]
}

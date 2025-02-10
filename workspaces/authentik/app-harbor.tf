module "oauth2_harbor" {
  source               = "../../modules/authentik-oauth2-application"
  name                 = "harbor"
  bitwarden_project_id = var.bitwarden_project_id
  client_id            = var.harbor_clientid
  icon_url             = "https://s3.homelab.${var.dns_zone}/homelab-authentik-media/media/public/application-icons/harbor.svg"
  launch_url           = "https://harbor.nas.${var.dns_zone}"
  signing_key_id       = data.authentik_certificate_key_pair.signing_key_pair.id

  groups = []
  flows = {
    authentication = null
    authorization  = data.authentik_flow.default_provider_authorization_implicit_consent.id
    invalidation   = data.authentik_flow.default_provider_invalidation_flow.id
  }
  property_mappings = concat(
    data.authentik_property_mapping_provider_scope.default.ids,
    data.authentik_property_mapping_provider_scope.offline_access.ids
  )
  redirect_uris = [{
    matching_mode = "strict"
    url           = "https://harbor.nas.${var.dns_zone}/c/oidc/callback"
  }]
}

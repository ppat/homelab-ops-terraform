resource "authentik_property_mapping_provider_scope" "minio" {
  name       = "OIDC-Scope-minio"
  scope_name = "minio"
  expression = <<EOF
if ak_is_group_member(request.user, name="homelab-admins"):
  return {
      "policy": "consoleAdmin",
}
elif ak_is_group_member(request.user, name="homelab-users"):
  return {
      "policy": ["readonly", "diagnostics"]
}
return None
EOF
}

module "oauth2_minio_nas" {
  source               = "../../modules/authentik-oauth2-application"
  name                 = "minio-nas"
  bitwarden_project_id = var.bitwarden_project_id
  client_id            = var.minio_nas_clientid
  icon_url             = "https://s3.homelab.${var.dns_zone}/homelab-authentik-media/media/public/application-icons/minio_dKwoWUN.svg"
  launch_url           = "https://minio-console.nas.${var.dns_zone}"
  signing_key_id       = data.authentik_certificate_key_pair.signing_key_pair.id

  groups = []
  flows = {
    authentication = null
    authorization  = data.authentik_flow.default_provider_authorization_implicit_consent.id
    invalidation   = data.authentik_flow.default_provider_invalidation_flow.id
  }
  property_mappings = concat(
    data.authentik_property_mapping_provider_scope.default.ids,
    [authentik_property_mapping_provider_scope.minio.id]
  )
  redirect_uris = [{
    matching_mode = "strict"
    url           = "https://minio-console.nas.${var.dns_zone}/oauth_callback"
  }]
}

module "oauth2_minio_homelab" {
  source               = "../../modules/authentik-oauth2-application"
  name                 = "minio-homelab"
  bitwarden_project_id = var.bitwarden_project_id
  client_id            = var.minio_homelab_clientid
  icon_url             = "https://s3.homelab.${var.dns_zone}/homelab-authentik-media/media/public/application-icons/minio.svg"
  launch_url           = "https://minio-console.homelab.${var.dns_zone}"
  signing_key_id       = data.authentik_certificate_key_pair.signing_key_pair.id

  groups = []
  flows = {
    authentication = null
    authorization  = data.authentik_flow.default_provider_authorization_implicit_consent.id
    invalidation   = data.authentik_flow.default_provider_invalidation_flow.id
  }
  property_mappings = concat(
    data.authentik_property_mapping_provider_scope.default.ids,
    [authentik_property_mapping_provider_scope.minio.id]
  )
  redirect_uris = [{
    matching_mode = "strict"
    url           = "https://minio-console.homelab.${var.dns_zone}/oauth_callback"
  }]
}

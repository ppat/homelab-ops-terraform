resource "authentik_property_mapping_provider_scope" "minio" {
  name       = "OIDC-Scope-minio"
  scope_name = "minio"
  expression = <<EOF
if ak_is_group_member(request.user, name="${data.authentik_group.homelab_admins.name}"):
  return {
      "policy": "consoleAdmin",
}
elif ak_is_group_member(request.user, name="${data.authentik_group.homelab_users.name}"):
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
  client_id            = var.clientid_minionas
  flows                = local.default_flows
  groups               = [data.authentik_group.homelab_admins.id, data.authentik_group.homelab_users.id]
  icon_url             = "https://s3.homelab.${var.dns_zone}/homelab-authentik-media/media/public/application-icons/minio_dKwoWUN.svg"
  launch_url           = "https://minio-console.nas.${var.dns_zone}"
  signing_key_id       = data.authentik_certificate_key_pair.signing_key_pair.id

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
  client_id            = var.clientid_miniohomelab
  flows                = local.default_flows
  groups               = [data.authentik_group.homelab_admins.id, data.authentik_group.homelab_users.id]
  icon_url             = "https://s3.homelab.${var.dns_zone}/homelab-authentik-media/media/public/application-icons/minio.svg"
  launch_url           = "https://minio-console.homelab.${var.dns_zone}"
  signing_key_id       = data.authentik_certificate_key_pair.signing_key_pair.id

  property_mappings = concat(
    data.authentik_property_mapping_provider_scope.default.ids,
    [authentik_property_mapping_provider_scope.minio.id]
  )
  redirect_uris = [{
    matching_mode = "strict"
    url           = "https://minio-console.homelab.${var.dns_zone}/oauth_callback"
  }]
}

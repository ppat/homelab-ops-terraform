module "oauth2_kuberneteshomelab" {
  source               = "../../modules/authentik-oauth2-application"
  name                 = "kubernetes-homelab"
  bitwarden_project_id = var.bitwarden_project_id
  client_id            = var.clientid_kuberneteshomelab
  flows                = local.default_flows
  groups               = [data.authentik_group.homelab_admins.id, data.authentik_group.homelab_users.id]
  signing_key_id       = data.authentik_certificate_key_pair.signing_key_pair.id

  property_mappings = concat(
    data.authentik_property_mapping_provider_scope.default.ids
  )
  redirect_uris = [{
    matching_mode = "strict"
    url           = "http://localhost:18000"
    }, {
    matching_mode = "strict"
    url           = "http://localhost:8000"
  }]
}

module "oauth2_kubernetesnas" {
  source               = "../../modules/authentik-oauth2-application"
  name                 = "kubernetes-nas"
  bitwarden_project_id = var.bitwarden_project_id
  client_id            = var.clientid_kubernetesnas
  flows                = local.default_flows
  groups               = [data.authentik_group.homelab_admins.id, data.authentik_group.homelab_users.id]
  signing_key_id       = data.authentik_certificate_key_pair.signing_key_pair.id

  property_mappings = concat(
    data.authentik_property_mapping_provider_scope.default.ids
  )
  redirect_uris = [{
    matching_mode = "strict"
    url           = "http://localhost:18000"
    }, {
    matching_mode = "strict"
    url           = "http://localhost:8000"
  }]
}

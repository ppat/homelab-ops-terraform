module "oauth2_grafana" {
  source               = "../../modules/authentik-oauth2-application"
  name                 = "grafana"
  bitwarden_project_id = var.bitwarden_project_id
  client_id            = var.clientid_grafana
  flows                = local.default_flows
  groups               = [data.authentik_group.homelab_admins.id, data.authentik_group.homelab_users.id]
  launch_url           = "https://grafana.homelab.${data.bitwarden_secret.dns_zone.value}"
  property_mappings    = data.authentik_property_mapping_provider_scope.default.ids
  signing_key_id       = data.authentik_certificate_key_pair.signing_key_pair.id

  redirect_uris = [{
    matching_mode = "strict"
    url           = "https://grafana.homelab.${data.bitwarden_secret.dns_zone.value}/login/generic_oauth"
  }]
}

module "proxy_alertmanager" {
  source          = "../../modules/authentik-proxy-application"
  name            = "alertmanager"
  application_url = "https://alertmanager.homelab.${data.bitwarden_secret.dns_zone.value}"
  flows           = local.default_flows
  groups          = [data.authentik_group.homelab_admins.id, data.authentik_group.homelab_users.id]
  launch_url      = "https://alertmanager.homelab.${data.bitwarden_secret.dns_zone.value}"

  property_mappings = concat(
    data.authentik_property_mapping_provider_scope.default.ids,
    data.authentik_property_mapping_provider_scope.entitlements.ids,
    data.authentik_property_mapping_provider_scope.proxy.ids
  )
}

module "proxy_prometheus" {
  source          = "../../modules/authentik-proxy-application"
  name            = "prometheus"
  application_url = "https://prometheus.homelab.${data.bitwarden_secret.dns_zone.value}"
  flows           = local.default_flows
  groups          = [data.authentik_group.homelab_admins.id, data.authentik_group.homelab_users.id]
  launch_url      = "https://prometheus.homelab.${data.bitwarden_secret.dns_zone.value}"

  property_mappings = concat(
    data.authentik_property_mapping_provider_scope.default.ids,
    data.authentik_property_mapping_provider_scope.entitlements.ids,
    data.authentik_property_mapping_provider_scope.proxy.ids
  )
}

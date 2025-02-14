module "proxy_lidarr" {
  source          = "../../modules/authentik-proxy-application"
  name            = "lidarr"
  application_url = "https://lidarr.homelab.${var.dns_zone}"
  flows           = local.default_flows
  groups          = [data.authentik_group.media_admins.id]
  launch_url      = "https://lidarr.homelab.${var.dns_zone}"

  property_mappings = concat(
    data.authentik_property_mapping_provider_scope.default.ids,
    data.authentik_property_mapping_provider_scope.entitlements.ids,
    data.authentik_property_mapping_provider_scope.proxy.ids
  )
}

module "proxy_prowlarr" {
  source          = "../../modules/authentik-proxy-application"
  name            = "prowlarr"
  application_url = "https://prowlarr.homelab.${var.dns_zone}"
  flows           = local.default_flows
  groups          = [data.authentik_group.media_admins.id]
  launch_url      = "https://prowlarr.homelab.${var.dns_zone}"

  property_mappings = concat(
    data.authentik_property_mapping_provider_scope.default.ids,
    data.authentik_property_mapping_provider_scope.entitlements.ids,
    data.authentik_property_mapping_provider_scope.proxy.ids
  )
}

module "proxy_radarr" {
  source          = "../../modules/authentik-proxy-application"
  name            = "radarr"
  application_url = "https://radarr.homelab.${var.dns_zone}"
  flows           = local.default_flows
  groups          = [data.authentik_group.media_admins.id]
  launch_url      = "https://radarr.homelab.${var.dns_zone}"

  property_mappings = concat(
    data.authentik_property_mapping_provider_scope.default.ids,
    data.authentik_property_mapping_provider_scope.entitlements.ids,
    data.authentik_property_mapping_provider_scope.proxy.ids
  )
}

module "proxy_sabnzbd" {
  source          = "../../modules/authentik-proxy-application"
  name            = "sabnzbd"
  application_url = "https://sabnzbd.homelab.${var.dns_zone}"
  flows           = local.default_flows
  groups          = [data.authentik_group.media_admins.id]
  launch_url      = "https://sabnzbd.homelab.${var.dns_zone}"

  property_mappings = concat(
    data.authentik_property_mapping_provider_scope.default.ids,
    data.authentik_property_mapping_provider_scope.entitlements.ids,
    data.authentik_property_mapping_provider_scope.proxy.ids
  )
}

module "proxy_sonarr" {
  source          = "../../modules/authentik-proxy-application"
  name            = "sonarr"
  application_url = "https://sonarr.homelab.${var.dns_zone}"
  flows           = local.default_flows
  groups          = [data.authentik_group.media_admins.id]
  launch_url      = "https://sonarr.homelab.${var.dns_zone}"

  property_mappings = concat(
    data.authentik_property_mapping_provider_scope.default.ids,
    data.authentik_property_mapping_provider_scope.entitlements.ids,
    data.authentik_property_mapping_provider_scope.proxy.ids
  )
}

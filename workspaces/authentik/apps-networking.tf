module "proxy_pihole" {
  source          = "../../modules/authentik-proxy-application"
  name            = "pihole"
  application_url = "https://pihole.homelab.${data.bitwarden_secret.dns_zone.value}"
  flows           = local.default_flows
  groups          = [data.authentik_group.homelab_admins.id, data.authentik_group.homelab_users.id]
  launch_url      = "https://pihole.homelab.${data.bitwarden_secret.dns_zone.value}"

  property_mappings = concat(
    data.authentik_property_mapping_provider_scope.default.ids,
    data.authentik_property_mapping_provider_scope.entitlements.ids,
    data.authentik_property_mapping_provider_scope.proxy.ids
  )
}

module "proxy_traefik_homelab" {
  source          = "../../modules/authentik-proxy-application"
  name            = "traefik-homelab"
  application_url = "https://traefik.homelab.${data.bitwarden_secret.dns_zone.value}"
  flows           = local.default_flows
  groups          = [data.authentik_group.homelab_admins.id, data.authentik_group.homelab_users.id]
  launch_url      = "https://traefik.homelab.${data.bitwarden_secret.dns_zone.value}"

  property_mappings = concat(
    data.authentik_property_mapping_provider_scope.default.ids,
    data.authentik_property_mapping_provider_scope.entitlements.ids,
    data.authentik_property_mapping_provider_scope.proxy.ids
  )
}

module "proxy_traefik_nas" {
  source          = "../../modules/authentik-proxy-application"
  name            = "traefik-nas"
  application_url = "https://traefik.nas.${data.bitwarden_secret.dns_zone.value}"
  flows           = local.default_flows
  groups          = [data.authentik_group.homelab_admins.id, data.authentik_group.homelab_users.id]
  launch_url      = "https://traefik.nas.${data.bitwarden_secret.dns_zone.value}"

  property_mappings = concat(
    data.authentik_property_mapping_provider_scope.default.ids,
    data.authentik_property_mapping_provider_scope.entitlements.ids,
    data.authentik_property_mapping_provider_scope.proxy.ids
  )
}

module "proxy_longhorn" {
  source          = "../../modules/authentik-proxy-application"
  name            = "longhorn"
  application_url = "https://longhorn.homelab.${data.bitwarden_secret.dns_zone.value}"
  flows           = local.default_flows
  groups          = [data.authentik_group.homelab_admins.id]
  icon_url        = "https://homelab-authentik-media.garage-web.homelab.${data.bitwarden_secret.dns_zone.value}/media/public/application-icons/longhorn.svg"
  launch_url      = "https://longhorn.homelab.${data.bitwarden_secret.dns_zone.value}"

  property_mappings = concat(
    data.authentik_property_mapping_provider_scope.default.ids,
    data.authentik_property_mapping_provider_scope.entitlements.ids,
    data.authentik_property_mapping_provider_scope.proxy.ids
  )
}

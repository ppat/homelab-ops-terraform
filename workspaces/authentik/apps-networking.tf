module "proxy_pihole" {
  source            = "../../modules/authentik-proxy-application"
  name              = "pihole"
  application_url   = "https://pihole.homelab.${var.dns_zone}"
  flows             = local.default_flows
  groups            = [data.authentik_group.homelab_admins.id, data.authentik_group.homelab_users.id]
  launch_url        = "https://pihole.homelab.${var.dns_zone}"
  property_mappings = data.authentik_property_mapping_provider_scope.default.ids
}

module "proxy_traefik_homelab" {
  source            = "../../modules/authentik-proxy-application"
  name              = "traefik-homelab"
  application_url   = "https://traefik.homelab.${var.dns_zone}"
  flows             = local.default_flows
  groups            = [data.authentik_group.homelab_admins.id, data.authentik_group.homelab_users.id]
  launch_url        = "https://traefik.homelab.${var.dns_zone}"
  property_mappings = data.authentik_property_mapping_provider_scope.default.ids
}

module "proxy_traefik_nas" {
  source            = "../../modules/authentik-proxy-application"
  name              = "traefik-nas"
  application_url   = "https://traefik.nas.${var.dns_zone}"
  flows             = local.default_flows
  groups            = [data.authentik_group.homelab_admins.id, data.authentik_group.homelab_users.id]
  launch_url        = "https://traefik.nas.${var.dns_zone}"
  property_mappings = data.authentik_property_mapping_provider_scope.default.ids
}

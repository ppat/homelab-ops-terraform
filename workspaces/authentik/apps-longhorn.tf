module "proxy_longhorn" {
  source            = "../../modules/authentik-proxy-application"
  name              = "longhorn"
  application_url   = "https://longhorn.homelab.${var.dns_zone}"
  flows             = local.default_flows
  groups            = [data.authentik_group.homelab_admins.id]
  icon_url          = "https://s3.homelab.${var.dns_zone}/homelab-authentik-media/media/public/application-icons/longhorn.svg"
  launch_url        = "https://longhorn.homelab.${var.dns_zone}"
  property_mappings = data.authentik_property_mapping_provider_scope.default.ids
}

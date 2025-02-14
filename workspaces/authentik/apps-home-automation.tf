module "proxy_home_assistant" {
  source          = "../../modules/authentik-proxy-application"
  name            = "home-assistant"
  application_url = "https://home-assistant.homelab.${var.dns_zone}"
  flows           = local.default_flows
  groups          = [data.authentik_group.homelab_users.id]
  launch_url      = "https://home-assistant.homelab.${var.dns_zone}"

  property_mappings = concat(
    data.authentik_property_mapping_provider_scope.default.ids,
    data.authentik_property_mapping_provider_scope.entitlements.ids,
    data.authentik_property_mapping_provider_scope.proxy.ids
  )
  unauthenticated_paths_regex = <<-EOT
  ^/api.*
  ^/auth/token.*
  ^/.external_auth=.
  ^/static.*
  ^/local.*
  ^/hacsfiles.*
  ^/frontend_latest.*
  ^/service_worker.js
  EOT
  # removed these from unauthenticated paths:
}

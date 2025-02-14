resource "authentik_application" "application" {
  name              = var.name
  slug              = lower(var.name)
  protocol_provider = authentik_provider_proxy.proxy_provider.id
  meta_icon         = var.icon_url
  meta_launch_url   = var.launch_url
  open_in_new_tab   = true
}

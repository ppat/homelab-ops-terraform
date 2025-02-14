resource "authentik_provider_proxy" "proxy_provider" {
  name              = "${var.name}-proxy"
  external_host     = var.application_url
  mode              = "forward_single"
  property_mappings = sort(var.property_mappings)
  skip_path_regex   = var.unauthenticated_paths_regex

  authentication_flow = var.flows.authentication
  authorization_flow  = var.flows.authorization
  invalidation_flow   = var.flows.invalidation

  access_token_validity  = var.validity.access_token
  refresh_token_validity = var.validity.refresh_token
}

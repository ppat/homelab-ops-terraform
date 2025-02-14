locals {
  default_flows = {
    authentication = null
    authorization  = data.authentik_flow.default_provider_authorization_implicit_consent.id
    invalidation   = data.authentik_flow.default_provider_invalidation_flow.id
  }
}

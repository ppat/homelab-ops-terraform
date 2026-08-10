# coder: a Coder environment (host key). Every model on the proxy, and broad MCP access — every
# self-hosted server, no tool filtering — both deliberate for this personally-controlled host
# (owner-confirmed 2026-08-10, see mcp-access-group.tf). MCP access comes entirely from being
# assigned to litellm_unified_access_group.self_hosted_mcp_broad there, by this module's
# key_id output — nothing MCP-related is passed to the module itself.
module "coder" {
  source = "../../modules/litellm-virtual-key"

  consumer            = "coder"
  unrestricted_models = true
  allowed_routes      = ["llm_api_routes"]

  bitwarden_project_id = var.bitwarden_project_id
  litellm_api_base     = var.litellm_api_base
  litellm_master_key   = var.litellm_master_key
}

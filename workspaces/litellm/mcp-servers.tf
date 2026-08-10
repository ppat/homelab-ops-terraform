# Remote/SaaS MCP servers ONLY — one modules/litellm-mcp-server instance per var.mcp_servers
# entry. Self-hosted MCP servers stay file-declared in the apps repo's LiteLLM HelmRelease and
# are not represented here. How each server is built and guarded against colliding with that
# file-declared set (by both server_name and alias) lives in the module; this file only says
# which servers exist. Name/alias hyphen validation lives on var.mcp_servers below since it's
# a property of the whole map's keys, not of any one server.
module "mcp_server" {
  source = "../../modules/litellm-mcp-server"

  for_each = var.mcp_servers

  server_name = each.key
  alias       = each.value.alias
  description = each.value.description
  url         = each.value.url
  transport   = each.value.transport
  auth_type   = each.value.auth_type

  credentials       = each.value.credentials
  static_headers    = each.value.static_headers
  allowed_tools     = each.value.allowed_tools
  mcp_access_groups = each.value.mcp_access_groups
  allow_all_keys    = each.value.allow_all_keys

  existing_mcp_servers = data.litellm_mcp_servers.all.mcp_servers
}

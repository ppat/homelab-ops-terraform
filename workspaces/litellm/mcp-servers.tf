# Collision guard rationale (see models.tf for the full explanation of the id-shape proxy;
# the ncecere/litellm provider's `litellm_mcp_servers` data source has the same gap — no
# field distinguishes file-declared from DB-declared servers, so this uses the same
# "id is not UUID-shaped => file-declared" heuristic).
#
# The hazard here is sharper than for models: LiteLLM's get_mcp_server_by_name() unions
# file-declared and DB-declared servers with file-declared ones enumerated FIRST, so a
# file-declared server always wins name resolution. A Terraform MCP server sharing a
# server_name *or* alias with a file-declared one becomes listed, healthy, and silently
# UNADDRESSABLE by name — worse than the models case, which merely dilutes a load-balancing
# pool. So this precondition checks both this server's server_name (the map key) and its
# optional alias against both the server_name and alias of every file-declared entry.
resource "litellm_mcp_server" "this" {
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

  lifecycle {
    precondition {
      condition = length([
        for s in data.litellm_mcp_servers.all.mcp_servers : s
        if !can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", s.server_id)) && (
          s.server_name == each.key ||
          s.alias == each.key ||
          (each.value.alias != null && (s.server_name == each.value.alias || s.alias == each.value.alias))
        )
      ]) == 0
      error_message = "server_name (or alias) for MCP server '${each.key}' collides with a file-declared server in the apps repo's LiteLLM HelmRelease. The file-declared server always wins name resolution, so this Terraform server would be listed, healthy, and silently unreachable by name — rename it."
    }
  }
}

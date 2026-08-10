# Collision guard rationale (see also modules/litellm-model/model.tf for the full explanation
# of the id-shape proxy; the ncecere/litellm provider's `litellm_mcp_servers` data source has
# the same gap — no field distinguishes file-declared from DB-declared servers, so this uses
# the same "id is not UUID-shaped => file-declared" heuristic).
#
# The hazard here is sharper than for models: LiteLLM's get_mcp_server_by_name() unions
# file-declared and DB-declared servers with file-declared ones enumerated FIRST, so a
# file-declared server always wins name resolution. A Terraform MCP server sharing a
# server_name *or* alias with a file-declared one becomes listed, healthy, and silently
# UNADDRESSABLE by name — worse than the models case, which merely dilutes a load-balancing
# pool. So this precondition checks both this server's server_name and its optional alias
# against both the server_name and alias of every file-declared entry.
#
# The discriminator's own liveness is not this module's concern — see the note at the bottom
# of modules/litellm-model/model.tf; it's checked once at the workspace level (see the `check`
# blocks in workspaces/litellm/main.tf) against the raw data source this module receives via
# var.existing_mcp_servers.
resource "litellm_mcp_server" "this" {
  server_name = var.server_name
  alias       = var.alias
  description = var.description
  url         = var.url
  transport   = var.transport
  auth_type   = var.auth_type

  credentials       = var.credentials
  static_headers    = var.static_headers
  allowed_tools     = var.allowed_tools
  mcp_access_groups = var.mcp_access_groups
  allow_all_keys    = var.allow_all_keys

  lifecycle {
    precondition {
      condition = length([
        for s in var.existing_mcp_servers : s
        if !can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", s.server_id)) && (
          s.server_name == var.server_name ||
          s.alias == var.server_name ||
          (var.alias != null && (s.server_name == var.alias || s.alias == var.alias))
        )
      ]) == 0
      error_message = "server_name (or alias) for MCP server '${var.server_name}' collides with a file-declared server in the apps repo's LiteLLM HelmRelease. The file-declared server always wins name resolution, so this Terraform server would be listed, healthy, and silently unreachable by name — rename it."
    }
  }
}

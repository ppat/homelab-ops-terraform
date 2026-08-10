# coder: a Coder environment (host key). Every model on the proxy, and untouched MCP access —
# both deliberate for this personally-controlled host (owner-confirmed 2026-08-10). This key
# has never had `models` or `object_permission` set at all, live today, and this module
# reproduces exactly that: unrestricted_models = true resolves to `models = null` (not an
# empty list — see the measured evidence in modules/litellm-virtual-key/key.tf), and simply
# never passing mcp_server_aliases/mcp_access_groups/mcp_tool_permissions leaves
# object_permission untouched (see the comment on mcp_server_aliases in that module's
# variables.tf). There is no separate "broad access" resource or mechanism — this key gets
# broad access the same way it does on the live proxy: by having no restriction configured.
module "coder" {
  source = "../../modules/litellm-virtual-key"

  consumer            = "coder"
  unrestricted_models = true
  allowed_routes      = ["llm_api_routes"]

  bitwarden_project_id = var.bitwarden_project_id
  litellm_api_base     = var.litellm_api_base
  litellm_master_key   = var.litellm_master_key
}

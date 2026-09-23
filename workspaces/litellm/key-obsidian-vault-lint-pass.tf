# obsidian-vault-lint-pass: the BRAIN knowledge vault's lint pass, a daily in-cluster CronJob in
# namespace `obsidian-vault` (ppat/homelab-ops-kubernetes-apps, module `apps-obsidian-vault`). It
# reads the vault from a read-only mount and writes only through the ingestor MCP server: frontmatter
# fixes as whole-note writes, its report and audit notes, and one appended `log.md` line. Created,
# not adopted, like key-obsidian-vault-batch-processor.tf — nothing presents it until that module
# ships the CronJob, so an apply that creates it rotates nothing.
#
# The consumer resolves exactly as the batch-processor key's does (see that file for why the string
# is not free to change):
#
#   gateway key_alias  obsidian-vault-lint-pass
#   Bitwarden secret   apikey_litellm_obsidianvaultlintpass
#
# The apps repository's ExternalSecret quotes the Bitwarden string verbatim
# (apps/subsystems/obsidian-vault/lint-pass/secrets.yaml).
#
# MCP: the ingestor server only, as for batch-processor, and for the same two-instance reason.
#
# TOOLS: exactly the three the lint pass calls, and NOT delete. The ingestor server exposes
# `obsidian_delete_note`; the lint pass never deletes, never renames and never moves a note, and
# ppat/obsidian-tools ADR-0004 places delete per handle rather than per server. This is where this
# key departs from batch-processor's, which applies patches that delete and therefore carries no
# allowlist — do not "align" the two.
#
# THE NAMES HERE ARE THE SERVER'S OWN, UNPREFIXED, while the workload's manifest names the same
# three tools WITH the gateway's alias prefix (`obsidian_ingestor-obsidian_get_note`). Both are
# right. `tools/list` through the gateway returns prefixed names, but the stored permission is
# matched against the bare name: LiteLLM strips the server prefix before both the listing filter
# and the call-time check (`filter_tools_by_key_team_permissions` and `pre_call_tool_check`, which
# receives `original_tool_name`, in litellm/proxy/_experimental/mcp_server). The adopted openclaw
# and n8n keys carry bare names live for the same reason. A prefixed entry here would match
# nothing and refuse every call the lint pass makes. The bare names were read from `tools/list`
# on the deployed gateway.
#
# The key of the map is the server name the `mcp_server_aliases` entry uses; LiteLLM resolves a
# tool-permission key by id, name or alias alike, and the module requires the two to agree.
#
# MODELS and ROUTES: as batch-processor's, for the reasons recorded there. The lint pass calls no
# LLM.
module "obsidian_vault_lint_pass" {
  source = "../../modules/litellm-virtual-key"

  consumer = "obsidian-vault-lint-pass"
  models   = ["no-model-access"]

  mcp_server_aliases = ["obsidian_ingestor_mcp"]
  mcp_tool_permissions = {
    obsidian_ingestor_mcp = [
      "obsidian_get_note",
      "obsidian_write_note",
      "obsidian_append_to_note",
    ]
  }

  allowed_routes = ["llm_api_routes"]

  note = "LiteLLM virtual key for the lint pass in the BRAIN knowledge vault (namespace obsidian-vault); scoped to the obsidian_ingestor_mcp MCP server's get_note, write_note and append_to_note tools, and no models"

  bitwarden_project_id = var.bitwarden_project_id
  litellm_api_base     = var.litellm_api_base
  litellm_master_key   = var.litellm_master_key
}

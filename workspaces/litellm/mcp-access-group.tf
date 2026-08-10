# Broad MCP access path ("Shape A") — litellm_unified_access_group, NOT object_permission.
#
# coder and golynniis (host keys — a Coder environment and a MacBook) need every self-hosted
# MCP server with no tool filtering, and need to keep getting new ones automatically as the
# apps repo's Helm values grow the catalog (owner-confirmed intentional, 2026-08-10). Listing
# every alias into each key's own object_permission.mcp_servers would NOT give that: every new
# server would need every broad-grant key's list edited by hand, and it braids a static
# enumeration into a mechanism (the module's REST seam, object-permission.tf) meant only for
# bespoke, per-key grants like openclaw/n8n's.
#
# Instead: one shared litellm_unified_access_group holding the current self-hosted server
# catalog, with broad-grant keys assigned to it BY key_id — a resource, and an attachment
# mechanism, entirely separate from object_permission. This lives at the workspace level, not
# inside modules/litellm-virtual-key, because assigned_key_ids is a SINGLE list attribute on
# ONE shared resource: if each key's module tried to own a slice of that list independently,
# whichever apply ran last would silently clobber the others' entries. Only the workspace sees
# every key at once, so only the workspace can safely compute the merged list — now just two
# concrete references (module.coder.key_id, module.golynniis.key_id) rather than a filter over
# a map, since both keys are named, committed module blocks (see key-coder.tf, key-golynniis.tf).
locals {
  # Every self-hosted MCP server declared in the apps repo's LiteLLM HelmRelease today,
  # confirmed by recomputing sha256(server_name|url|transport|auth_type|alias)[:32] against the
  # live proxy (all 12 hashes distinct, all 12 resolve to a non-empty alias via
  # litellm_settings.mcp_aliases). 5 of these are ALSO granted individually to openclaw/n8n via
  # their own bespoke object_permission (key-openclaw.tf, key-n8n.tf) — that's a separate,
  # narrower grant through a different mechanism, not a conflict with this broader one.
  # Currently ungranted to anyone except through this access group: kubernetes_homelab,
  # kubernetes_nas, kubernetes_sandbox, unifi_network, unifi_protect, obsidian_agent,
  # obsidian_ingestor. Adding a 13th self-hosted server later is one entry here, not a
  # per-key edit.
  self_hosted_mcp_server_aliases = [
    "context7",
    "playwright",
    "grafana",
    "home_assistant",
    "github",
    "kubernetes_homelab",
    "kubernetes_nas",
    "kubernetes_sandbox",
    "unifi_network",
    "unifi_protect",
    "obsidian_agent",
    "obsidian_ingestor",
  ]

  # access_mcp_server_ids wants real server IDs, not aliases — unlike object_permission, this
  # field's alias-resolution behavior isn't something this design has verified (see the REST
  # seam's comment on why aliases are safe there specifically: it's the same resolution LiteLLM
  # uses at request time, everywhere, confirmed for object_permission). Rather than gamble on the
  # same resolution applying here, or hardcode the file-declared servers' internal hash IDs
  # (unstable across a URL change — see modules/litellm-mcp-server/mcp-server.tf), this resolves
  # aliases to real IDs itself via the live data.litellm_mcp_servers.all data source (main.tf).
  self_hosted_mcp_server_ids_by_alias = {
    for alias in local.self_hosted_mcp_server_aliases :
    alias => one([
      for s in data.litellm_mcp_servers.all.mcp_servers : s.server_id
      if s.alias == alias || s.server_name == alias
    ])
  }
}

resource "litellm_unified_access_group" "self_hosted_mcp_broad" {
  access_group_name     = "self-hosted-mcp-broad-access"
  description           = "Every self-hosted MCP server, no tool filtering — for keys that intentionally need broad access (host keys today: coder, golynniis). Membership in access_mcp_server_ids is maintained via local.self_hosted_mcp_server_aliases above, not per-key config."
  access_mcp_server_ids = [for alias in local.self_hosted_mcp_server_aliases : local.self_hosted_mcp_server_ids_by_alias[alias]]
  assigned_key_ids      = [module.coder.key_id, module.golynniis.key_id]

  lifecycle {
    # Every alias must resolve to exactly one live server_id. `one(...)` returns null for zero
    # matches; a typo'd or not-yet-existing alias would otherwise surface only as an opaque
    # "null value" error deep inside access_mcp_server_ids, far from its cause.
    precondition {
      condition     = alltrue([for alias, id in local.self_hosted_mcp_server_ids_by_alias : id != null])
      error_message = "One or more self_hosted_mcp_server_aliases entries did not resolve to a server_id via data.litellm_mcp_servers.all — check for a typo, or a server that doesn't exist on the proxy yet. Unresolved aliases: ${join(", ", [for alias, id in local.self_hosted_mcp_server_ids_by_alias : alias if id == null])}"
    }
  }
}

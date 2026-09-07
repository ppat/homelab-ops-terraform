# obsidian-vault-batch-processor: the BRAIN knowledge vault's bulk work consumer, an in-cluster
# CronJob in namespace `obsidian-vault` (ppat/homelab-ops-kubernetes-apps, module
# `apps-obsidian-vault`). The FIRST key in this workspace that is CREATED rather than adopted —
# every other key-<consumer>.tf here documents an import of a hand-minted credential
# (keys-import.tf). Nothing presents this key today, so an apply that creates it rotates nothing.
#
# THE CONSUMER STRING IS THE NAME, THREE TIMES OVER, AND IT IS NOT FREE TO CHANGE.
# `var.consumer` becomes the LiteLLM key_alias verbatim, the terracurl request name, and — with
# every non-alphanumeric character stripped — the Bitwarden secret name
# (modules/litellm-virtual-key/bitwarden.tf). So this consumer resolves to:
#
#   gateway key_alias  obsidian-vault-batch-processor   (namespace + workload, as deployed)
#   Bitwarden secret   apikey_litellm_obsidianvaultbatchprocessor
#
# The Bitwarden name runs together because the module strips the hyphens; that is accepted here
# rather than shortened. Read cold in a Bitwarden project that also holds keys for OpenClaw, n8n
# and two laptops, "batch processor" names a role that could belong to any system in the homelab,
# so the vault's own name has to be carried in the credential. The apps repository's
# ExternalSecret must quote that generated string exactly
# (apps/subsystems/obsidian-vault/batch-processor/secrets.yaml) — a mismatch there is not a partial
# sync, it is an ExternalSecret that never resolves and a pod stuck in CreateContainerConfigError.
# Renaming this consumer later is a destroy-and-recreate of a live credential, not an edit.
#
# MCP: exactly one server, and this is the whole point of the key. `batch-processor` mounts no
# vault volume and never reaches the Obsidian REST API; every read, write and delete it performs
# is an MCP tool call through the gateway to the ingestor-scoped instance. `obsidian_ingestor_mcp`
# is the server's registered name in the gateway's file-declared catalog (that module's LiteLLM
# HelmRelease `proxy_config.mcp_servers`) — not a Terraform-managed object, which is why
# mcp-servers.tf has no obsidian entry and does not need one: object_permission resolves an entry
# by alias/server_name, and nothing requires the referenced server to be Terraform-managed.
# Granting `obsidian_agent_mcp` here as well would hand the agent zone's writer the ingestor's
# wide path scope and vice versa, collapsing the two-instance separation the vault is built on
# (ppat/obsidian-tools ADR-0003).
#
# No mcp_tool_permissions, deliberately, and this is a deferral rather than a decision that broad
# tool access is right. The three tool names this workload calls are marked UNVERIFIED in the
# workload's own manifest (batch-processor/cronjob.yaml) — inferred from the server image, never
# checked against `tools/list` on the deployed gateway. A tool allowlist transcribed from an
# inference fails closed at every call site of a real import run, which is a worse outcome than
# the server-level scoping already achieved here. Add the allowlist once the vocabulary is
# verified post-cutover; the module's own precondition already requires its keys to be a subset of
# mcp_server_aliases.
#
# MODELS: a name no model has, which is this gateway's only way to say "none". `batch-processor`
# applies patches; it calls no LLM. An empty models list would be the opposite of that — LiteLLM
# treats empty as UNRESTRICTED and has no key-level deny-all (the footgun documented at length on
# var.unrestricted_models in the module's variables.tf), and the module's XOR precondition refuses
# to let a key be silently unrestricted by omission. A single-entry list naming nothing in the
# catalog is therefore the narrowest grant expressible. This costs the key nothing it needs: the
# models check is never invoked on MCP endpoints, so it constrains only what a stolen key could
# spend. If a model called `no-model-access` is ever added to the catalog, this stops being a
# deny-all — the name is chosen not to collide, not defended against collision.
module "obsidian_vault_batch_processor" {
  source = "../../modules/litellm-virtual-key"

  consumer = "obsidian-vault-batch-processor"
  models   = ["no-model-access"]

  mcp_server_aliases = ["obsidian_ingestor_mcp"]

  # Matching the five adopted keys rather than narrowing further. openclaw and n8n carry exactly
  # this value live while using MCP tool calls daily, which is what proves an MCP-only consumer is
  # not locked out by it; a narrower route set would be a guess at LiteLLM's route-group names that
  # fails as a total outage for this key rather than as a plan error.
  allowed_routes = ["llm_api_routes"]

  # The five adopted secrets all carry an empty note, because that is what they were minted with
  # and the module reproduces live state rather than improving on it. This one is created, not
  # adopted, so there is no live state to contradict — and a note is the only place the run-together
  # Bitwarden name can be expanded back into words for whoever finds it in the vault later.
  note = "LiteLLM virtual key for batch-processor in the BRAIN knowledge vault (namespace obsidian-vault); scoped to the obsidian_ingestor_mcp MCP server and no models"

  bitwarden_project_id = var.bitwarden_project_id
  litellm_api_base     = var.litellm_api_base
  litellm_master_key   = var.litellm_master_key
}

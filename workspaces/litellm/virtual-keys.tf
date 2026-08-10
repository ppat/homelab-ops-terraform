# Terraform-managed virtual keys ONLY — one modules/litellm-virtual-key instance per
# var.virtual_keys entry. How each key is built (including the object_permission REST
# seam bridging ncecere/litellm's gap — see modules/litellm-virtual-key/object-permission.tf)
# lives in the module; this file only says which keys exist and threads through the
# shared litellm_api_base/litellm_master_key/bitwarden_project_id every instance needs.
module "virtual_key" {
  source = "../../modules/litellm-virtual-key"

  for_each = var.virtual_keys

  consumer = each.key
  models   = each.value.models

  mcp_server_aliases   = each.value.mcp_server_aliases
  mcp_access_groups    = each.value.mcp_access_groups
  mcp_tool_permissions = each.value.mcp_tool_permissions

  team_id               = each.value.team_id
  max_budget            = each.value.max_budget
  budget_duration       = each.value.budget_duration
  tpm_limit             = each.value.tpm_limit
  rpm_limit             = each.value.rpm_limit
  max_parallel_requests = each.value.max_parallel_requests
  duration              = each.value.duration
  blocked               = each.value.blocked
  metadata              = each.value.metadata
  tags                  = each.value.tags

  bitwarden_project_id = var.bitwarden_project_id
  litellm_api_base     = var.litellm_api_base
  litellm_master_key   = var.litellm_master_key
}

# ==============================================================================
# Broad MCP access path ("Shape A") — litellm_unified_access_group, NOT object_permission
# ==============================================================================
#
# A key with `broad_mcp_access = true` in var.virtual_keys (coder, golynniis today) needs
# every self-hosted MCP server with no tool filtering, and needs to keep getting new ones
# automatically as the apps repo's Helm values grow the catalog — the same "no Terraform
# change needed" requirement that drives the models = ["all-proxy-models"] sentinel (see
# the comment on var.models in modules/litellm-virtual-key/variables.tf). Enumerating all
# server aliases into that key's own object_permission.mcp_servers would NOT give that:
# every new server would need every broad-grant key's list edited by hand, and it braids
# a static enumeration into a mechanism (the REST seam) meant only for bespoke, per-key
# grants.
#
# Instead: one shared litellm_unified_access_group holding the current self-hosted server
# catalog, with broad-grant keys assigned to it BY key_id — a resource, and an attachment
# mechanism, entirely separate from object_permission. This lives here, not inside the
# module, because assigned_key_ids is a SINGLE list attribute on ONE shared resource: if
# each module instance tried to own a slice of that same list independently, whichever
# apply ran last would silently clobber the others' entries. Only the workspace sees every
# instance at once (via var.virtual_keys), so only the workspace can safely compute the
# merged list. It also decouples these keys' MCP access from whatever grants them broad
# access today (see the IMPORT notes below on the still-open admin-role question) — adding
# a 13th self-hosted server becomes one edit to var.self_hosted_mcp_server_aliases, and no
# key's own config changes at all.
#
# access_mcp_server_ids wants real server IDs, not aliases — unlike object_permission,
# this field's alias-resolution behavior isn't something this design has verified (see the
# REST seam's comment on why aliases are safe there specifically: it's the same resolution
# LiteLLM uses at request time, everywhere, confirmed for object_permission). Rather than
# gamble on the same resolution applying here, or hardcode the file-declared servers'
# internal hash IDs (unstable across a URL change — see modules/litellm-mcp-server/
# mcp-server.tf), this resolves aliases to real IDs itself via the live
# data.litellm_mcp_servers.all data source already declared in main.tf.
locals {
  self_hosted_mcp_server_ids_by_alias = {
    for alias in var.self_hosted_mcp_server_aliases :
    alias => one([
      for s in data.litellm_mcp_servers.all.mcp_servers : s.server_id
      if s.alias == alias || s.server_name == alias
    ])
  }
}

resource "litellm_unified_access_group" "self_hosted_mcp_broad" {
  count = length([for k, v in var.virtual_keys : k if v.broad_mcp_access]) > 0 ? 1 : 0

  access_group_name     = "self-hosted-mcp-broad-access"
  description           = "Every self-hosted MCP server, no tool filtering — for keys that intentionally need broad access (host keys today: coder, golynniis). Membership in access_mcp_server_ids is maintained via var.self_hosted_mcp_server_aliases, not per-key config."
  access_mcp_server_ids = [for alias in var.self_hosted_mcp_server_aliases : local.self_hosted_mcp_server_ids_by_alias[alias]]
  assigned_key_ids      = [for k, v in var.virtual_keys : module.virtual_key[k].key_id if v.broad_mcp_access]

  lifecycle {
    precondition {
      condition     = length([for k, v in var.virtual_keys : k if v.broad_mcp_access]) == 0 || length(var.self_hosted_mcp_server_aliases) > 0
      error_message = "At least one virtual_keys entry sets broad_mcp_access = true, but self_hosted_mcp_server_aliases is empty — that key would be assigned to an access group granting zero servers, which is a silent 'broad access' that grants nothing. Populate self_hosted_mcp_server_aliases with the current self-hosted MCP server catalog."
    }
    precondition {
      # Every alias must resolve to exactly one live server_id. `one(...)` returns null for
      # zero matches; a typo'd or not-yet-existing alias would otherwise surface only as an
      # opaque "null value" error deep inside access_mcp_server_ids, far from its cause.
      condition     = alltrue([for alias, id in local.self_hosted_mcp_server_ids_by_alias : id != null])
      error_message = "One or more self_hosted_mcp_server_aliases entries did not resolve to a server_id via data.litellm_mcp_servers.all — check for a typo, or a server that doesn't exist on the proxy yet. Unresolved aliases: ${join(", ", [for alias, id in local.self_hosted_mcp_server_ids_by_alias : alias if id == null])}"
    }
  }
}

# ==============================================================================
# IMPORT — adopting the five hand-minted keys (DO NOT let terraform apply create them)
# ==============================================================================
#
# Five virtual keys already exist, hand-minted in the LiteLLM Admin UI, each live and in
# use by a real consumer. They must be ADOPTED into Terraform state via `terraform
# import`, never recreated — recreating any of them rotates a live credential and breaks
# whatever is presenting it today. This repo's owner runs the imports below by hand;
# nothing in this codebase invents or stores the plaintext sk-... values needed to do it.
#
# Live shape per consumer (confirmed against GET /key/list on the homelab proxy; see the
# scratchpad live-key-inventory for full detail — not committed here, it's an operational
# snapshot, not code):
#   - openclaw: 8 explicit models; MCP via explicit object_permission — 5 servers
#     (context7, playwright, grafana, home_assistant, github), each with its OWN
#     bespoke mcp_tool_permissions (openclaw's grafana grant is far broader than n8n's —
#     these are NOT copies of one profile). broad_mcp_access = false.
#   - n8n: 5 explicit models; same 5 servers as openclaw, different (narrower) tool
#     allowlists. broad_mcp_access = false.
#   - coder, golynniis: models = ["all-proxy-models"] (currently [] live — see the KNOWN
#     DIFF note below). broad_mcp_access = true — the only two keys on the shared
#     litellm_unified_access_group above.
#   - openwebui: models = ["all-proxy-models"] (currently [] live). broad_mcp_access =
#     false — openwebui does not need MCP access; it stays at the module's default
#     (zero servers, object_permission left untouched — see object-permission.tf).
#
# Bitwarden: all five secrets already live in project e9c6c45e-e8d9-480c-b2cf-b204011e80e6
# (same shared infra project the ExternalSecrets machine account uses) — that's the real
# value for TF_VAR_bitwarden_project_id, supplied by the owner outside this repo, never
# hardcoded here per house style (see modules/litellm-virtual-key/bitwarden.tf).
#
# Procedure per consumer (repeat for openwebui, n8n, openclaw, coder, golynniis):
#
#   1. Add that consumer's real entry to var.virtual_keys (a *.auto.tfvars.json, a
#      TF_VAR_virtual_keys env var, or similar — not committed to this repo) matching the
#      live shape above as closely as possible. This matters: if the values here don't
#      match live state, the import "succeeds" but the very next plan tries to change a
#      real key's models/limits, which is exactly the kind of surprise this design exists
#      to prevent.
#
#   2. Import the litellm_key resource, using the key's plaintext sk-... value (from
#      wherever it's currently stored/used — never from GET /key/info, which only
#      returns a hash) as the import ID:
#
#        terraform import 'module.virtual_key["openwebui"].litellm_key.this' sk-...
#        terraform import 'module.virtual_key["n8n"].litellm_key.this'       sk-...
#        terraform import 'module.virtual_key["openclaw"].litellm_key.this'  sk-...
#        terraform import 'module.virtual_key["coder"].litellm_key.this'     sk-...
#        terraform import 'module.virtual_key["golynniis"].litellm_key.this' sk-...
#
#   3. Import the Bitwarden secret that already holds that plaintext. The
#      maxlaverse/bitwarden provider's import is a plain passthrough onto the secret's own
#      `id` (operation_secret.go: opSecretImport does `d.SetId(d.Id())`, then reads the
#      rest from Bitwarden by that ID) — so the import ID is just the secret's Bitwarden
#      UUID, confirmed values below:
#
#        terraform import 'module.virtual_key["openwebui"].bitwarden_secret.apikey'  410148df-6af6-42aa-a630-b48f010933b4
#        terraform import 'module.virtual_key["n8n"].bitwarden_secret.apikey'        b6996272-22b5-44d0-bb50-b4920159d75d
#        terraform import 'module.virtual_key["openclaw"].bitwarden_secret.apikey'   4d01d84e-6ca3-4674-9a99-b492015c5faf
#        terraform import 'module.virtual_key["coder"].bitwarden_secret.apikey'      3d97880e-879d-48ed-aa1c-b4910081d2ef
#        terraform import 'module.virtual_key["golynniis"].bitwarden_secret.apikey'  b443797d-f93f-4e01-a8ae-b49100825b18
#
#   4. Run `terraform plan` and read it before touching anything else.
#
# What the plan SHOULD show after step 4, and why:
#
#   - litellm_key.this: NO changes for openclaw and n8n (their live config is fully
#     explicit and reproducible in HCL). For openwebui/coder/golynniis: a KNOWN, EXPECTED
#     diff on `models`, from live `[]` to desired `["all-proxy-models"]` — both mean
#     "every model" (verified in LiteLLM v1.93.0 source: auth_checks.py:2877-2881 checks
#     `len(models) == 0` and `all_proxy_models in filtered_models` as equally-unrestricted
#     branches, and empirically against a sandbox proxy: a key with either form gets past
#     the model-access gate for a model name that didn't exist at key-creation time,
#     while an explicitly-scoped key gets a 403 for the same call), so this specific diff
#     changes nothing about what the key can actually do — it only replaces an implicit
#     grant with a stated one, which is the entire point of this module's validation.
#     This is the ONE pre-approved exception to "no changes expected" — any OTHER diff on
#     litellm_key.this, especially anything touching `models` beyond that exact `[]` ->
#     `["all-proxy-models"]` transition, means the var.virtual_keys entry doesn't match
#     live state. Stop and fix it before applying; do not apply a plan that changes this
#     resource without understanding exactly why.
#
#   - bitwarden_secret.apikey: NO changes, once its `value` matches the plaintext already
#     stored in that Bitwarden secret (which it should, since that plaintext IS this
#     key's token).
#
#   - terracurl_request.object_permission: for openclaw/n8n, WILL show as "1 to add" — this
#     is expected, not a sign of a bad import: it's a brand-new Terraform-only resource
#     with no remote object to adopt (there's nothing meaningful to `terraform import`
#     here — it's a one-shot HTTP call, not an addressable object). Applying it re-POSTs
#     object_permission to values that should already match what's live today, so it's a
#     safe, idempotent no-op against the proxy even though Terraform reports it as a
#     create. For openwebui/coder/golynniis, this resource won't exist at all (count = 0
#     — see object-permission.tf), so nothing to expect here.
#
#   - litellm_unified_access_group.self_hosted_mcp_broad: WILL show as "1 to add" once
#     self_hosted_mcp_server_aliases and coder/golynniis's broad_mcp_access = true are both
#     populated — same reasoning as the terracurl resource: a new, native Terraform
#     resource with nothing to adopt, whose apply is expected to be a safe, additive
#     no-op against what those two keys can already do (see the open question below).
#
# So: "no-op" is the bar for litellm_key and bitwarden_secret specifically (modulo the one
# pre-approved models diff above) — those are the two resources where a surprise change is
# the actual hazard (rotated credential, clobbered secret). A clean first plan means those
# two show nothing unexpected, not that the whole plan is empty.
#
# STILL OPEN, OWNER TO CONFIRM BEFORE WIRING coder/golynniis'S broad_mcp_access: how do
# these two keys currently get MCP access at all? LiteLLM's own source
# (mcp_server_manager.py: get_allowed_mcp_servers) gives a non-admin key with
# object_permission = None (their live state) ZERO servers — no config-level
# allow_all_keys override exists anywhere in the apps repo's Helm values (confirmed: field
# never set, defaults False in 4 places in LiteLLM source). The remaining explanation is
# that these two keys carry Proxy Admin role (both have user_id "default_user_id"), which
# grants every server implicitly (mcp_server_manager.py:1729) — and, if so, plausibly the
# management API too, not just models+MCP. The owner has confirmed broad MCP+model access
# for these two hosts is INTENTIONAL; what's still unconfirmed is the CURRENT mechanism,
# which matters here specifically because assigning them to
# litellm_unified_access_group.self_hosted_mcp_broad only ADDS an explicit, admin-
# independent grant — it does not by itself remove any admin role they may already hold.
# If de-privileging them to non-admin is ever desired, confirm the access group covers
# everything they need FIRST (it's designed to), then drop the admin role separately —
# that ordering avoids a gap where a key temporarily has neither.

# ==============================================================================
# IMPORT — adopting the five hand-minted keys (DO NOT let terraform apply create them)
# ==============================================================================
#
# Five virtual keys already exist, hand-minted in the LiteLLM Admin UI, each live and in use
# by a real consumer: openwebui, coder, golynniis (written — key-openwebui.tf, key-coder.tf,
# key-golynniis.tf), and n8n, openclaw (not yet written — see key-n8n.tf, key-openclaw.tf for
# why). They must be ADOPTED into Terraform state via `terraform import`, never recreated —
# recreating any of them rotates a live credential and breaks whatever is presenting it today.
# This repo's owner runs the imports below by hand; nothing in this codebase invents or stores
# the plaintext sk-... values needed to do it.
#
# Unlike the map-variable shape this replaced, there is no "populate a tfvars file to match
# live state" step here — the config IS the repo. Each key-<consumer>.tf file is real,
# committed, reviewed HCL, so the first plan after import verifies THAT CODE against live
# state, not an untracked file nobody reviewed. That's the entire point of this shape: the
# per-server tool allowlists (once key-n8n.tf/key-openclaw.tf are filled in) become reviewable,
# versioned code instead of a blob no one else ever saw.
#
# Bitwarden: all five secrets already live in project e9c6c45e-e8d9-480c-b2cf-b204011e80e6
# (same shared infra project the ExternalSecrets machine account uses) — that's the real value
# for TF_VAR_bitwarden_project_id, supplied by the owner outside this repo, never hardcoded
# here per house style (see modules/litellm-virtual-key/bitwarden.tf).
#
# Procedure per consumer, once its key-<consumer>.tf file has real config committed:
#
#   1. Import the litellm_key resource, using the key's plaintext sk-... value (from wherever
#      it's currently stored/used — never from GET /key/info, which only returns a hash) as
#      the import ID:
#
#        terraform import 'module.openwebui.litellm_key.this'  sk-...
#        terraform import 'module.coder.litellm_key.this'      sk-...
#        terraform import 'module.golynniis.litellm_key.this'  sk-...
#        terraform import 'module.n8n.litellm_key.this'        sk-...   # once key-n8n.tf exists
#        terraform import 'module.openclaw.litellm_key.this'   sk-...   # once key-openclaw.tf exists
#
#   2. Import the Bitwarden secret that already holds that plaintext. The maxlaverse/bitwarden
#      provider's import is a plain passthrough onto the secret's own `id`
#      (operation_secret.go: opSecretImport does `d.SetId(d.Id())`, then reads the rest from
#      Bitwarden by that ID) — so the import ID is just the secret's Bitwarden UUID, confirmed
#      values below:
#
#        terraform import 'module.openwebui.bitwarden_secret.apikey'  410148df-6af6-42aa-a630-b48f010933b4
#        terraform import 'module.coder.bitwarden_secret.apikey'      3d97880e-879d-48ed-aa1c-b4910081d2ef
#        terraform import 'module.golynniis.bitwarden_secret.apikey'  b443797d-f93f-4e01-a8ae-b49100825b18
#        terraform import 'module.n8n.bitwarden_secret.apikey'        b6996272-22b5-44d0-bb50-b4920159d75d
#        terraform import 'module.openclaw.bitwarden_secret.apikey'   4d01d84e-6ca3-4674-9a99-b492015c5faf
#
#   3. Run `terraform plan` and read it before touching anything else.
#
# What the plan SHOULD show after step 3, and why:
#
#   - litellm_key.this: NO changes for n8n and openclaw, once written (their live config is
#     fully explicit and reproducible in HCL). For openwebui/coder/golynniis: a KNOWN, EXPECTED
#     diff on `models`, from live `[]` to desired `["all-proxy-models"]` — the literal wire
#     value that `unrestricted_models = true` resolves to internally (see
#     modules/litellm-virtual-key/key.tf's `local.resolved_models`). Both mean "every model"
#     (verified in LiteLLM v1.93.0 source: auth_checks.py:2877-2881 checks `len(models) == 0`
#     and `all_proxy_models in filtered_models` as equally-unrestricted branches, and
#     empirically against a sandbox proxy: a key with either form gets past the model-access
#     gate for a model name that didn't exist at key-creation time, while an explicitly-scoped
#     key gets a 403 for the same call), so this specific diff changes nothing about what the
#     key can actually do — it only replaces an implicit grant with a stated one
#     (unrestricted_models = true in HCL), which is the entire point of this module's
#     models/unrestricted_models pair. This is the ONE pre-approved exception to "no changes
#     expected" — any OTHER diff on litellm_key.this, especially anything touching `models`
#     beyond that exact `[]` -> `["all-proxy-models"]` transition, means the committed config
#     doesn't match live state. Stop and fix the key-<consumer>.tf file before applying; do not
#     apply a plan that changes this resource without understanding exactly why.
#
#   - bitwarden_secret.apikey: NO changes, once its `value` matches the plaintext already
#     stored in that Bitwarden secret (which it should, since that plaintext IS this key's
#     token).
#
#   - terracurl_request.object_permission: for n8n/openclaw once written, WILL show as "1 to
#     add" — this is expected, not a sign of a bad import: it's a brand-new Terraform-only
#     resource with no remote object to adopt (there's nothing meaningful to `terraform import`
#     here — it's a one-shot HTTP call, not an addressable object). Applying it re-POSTs
#     object_permission to values that should already match what's live today, so it's a safe,
#     idempotent no-op against the proxy even though Terraform reports it as a create. For
#     openwebui/coder/golynniis, this resource won't exist at all (count = 0 — see
#     object-permission.tf), so nothing to expect here.
#
#   - litellm_unified_access_group.self_hosted_mcp_broad (mcp-access-group.tf): WILL show as
#     "1 to add" — same reasoning as the terracurl resource: a new, native Terraform resource
#     with nothing to adopt, whose apply is expected to be a safe, additive no-op against what
#     coder/golynniis can already do (see the open admin-role question below).
#
# So: "no-op" is the bar for litellm_key and bitwarden_secret specifically (modulo the one
# pre-approved models diff above) — those are the two resources where a surprise change is the
# actual hazard (rotated credential, clobbered secret). A clean first plan means those two show
# nothing unexpected, not that the whole plan is empty.
#
# STILL OPEN, OWNER TO CONFIRM BEFORE IMPORTING coder/golynniis: how do these two keys
# currently get MCP access at all? LiteLLM's own source (mcp_server_manager.py:
# get_allowed_mcp_servers) gives a non-admin key with object_permission = None (their live
# state) ZERO servers — no config-level allow_all_keys override exists anywhere in the apps
# repo's Helm values (confirmed: field never set, defaults False in 4 places in LiteLLM
# source). The remaining explanation is that these two keys carry Proxy Admin role (both have
# user_id "default_user_id"), which grants every server implicitly (mcp_server_manager.py:
# 1729) — and, if so, plausibly the management API too, not just models+MCP. The owner has
# confirmed broad MCP+model access for these two hosts is INTENTIONAL; what's still unconfirmed
# is the CURRENT mechanism, which matters here specifically because assigning them to
# litellm_unified_access_group.self_hosted_mcp_broad only ADDS an explicit, admin-independent
# grant — it does not by itself remove any admin role they may already hold. If de-privileging
# them to non-admin is ever desired, confirm the access group covers everything they need FIRST
# (it's designed to), then drop the admin role separately — that ordering avoids a gap where a
# key temporarily has neither.

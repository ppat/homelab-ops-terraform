# ==============================================================================
# IMPORT — adopting the five hand-minted keys (DO NOT let terraform apply create them)
# ==============================================================================
#
# This file is about the five ADOPTED keys only. The workspace also holds one key that is
# genuinely created by Terraform — obsidian-vault-batch-processor, see
# key-obsidian-vault-batch-processor.tf — which nothing presents yet and which must NOT be
# imported. The distinction is the whole hazard this file exists to name: an import that should
# have been a create leaves Terraform managing a key nobody holds, and a create that should have
# been an import rotates a live credential. Read the last section below before reading a plan that
# contains both.
#
# Five virtual keys already exist, hand-minted in the LiteLLM Admin UI, each live and in use by
# a real consumer: openwebui, coder, golynniis, n8n, openclaw — all five now have real,
# committed config (key-openwebui.tf, key-coder.tf, key-golynniis.tf, key-n8n.tf,
# key-openclaw.tf; n8n/openclaw's model lists and per-server MCP tool allowlists were
# transcribed verbatim from the owner-supplied live-key-config-verbatim.json and verified
# programmatically against that source — see the PR description/report for the method and
# counts). They must be ADOPTED into Terraform state via `terraform import`, never recreated —
# recreating any of them rotates a live credential and breaks whatever is presenting it today.
# This repo's owner runs the imports below by hand; nothing in this codebase invents or stores
# the plaintext sk-... values needed to do it.
#
# Unlike the map-variable shape this replaced, there is no "populate a tfvars file to match
# live state" step here — the config IS the repo. Each key-<consumer>.tf file is real,
# committed, reviewed HCL, so the first plan after import verifies THAT CODE against live
# state, not an untracked file nobody reviewed. That's the entire point of this shape: the
# per-server tool allowlists are reviewable, versioned code instead of a blob no one else
# ever saw.
#
# Bitwarden: all five secrets already live in project e9c6c45e-e8d9-480c-b2cf-b204011e80e6
# (same shared infra project the ExternalSecrets machine account uses) — that's the real value
# for TF_VAR_bitwarden_project_id, supplied by the owner outside this repo, never hardcoded
# here per house style (see modules/litellm-virtual-key/bitwarden.tf).
#
# Procedure per consumer (repeat for openwebui, coder, golynniis, n8n, openclaw):
#
#   1. Import the litellm_key resource, using the key's plaintext sk-... value (from wherever
#      it's currently stored/used — never from GET /key/info, which only returns a hash) as
#      the import ID:
#
#        terraform import 'module.openwebui.litellm_key.this'  sk-...
#        terraform import 'module.coder.litellm_key.this'      sk-...
#        terraform import 'module.golynniis.litellm_key.this'  sk-...
#        terraform import 'module.n8n.litellm_key.this'        sk-...
#        terraform import 'module.openclaw.litellm_key.this'   sk-...
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
#   - litellm_key.this: NO changes, for ALL FIVE keys — a true no-op, not a "modulo one known
#     diff" one. For n8n/openclaw that's because their live config is fully explicit and
#     transcribed verbatim (verified against the source, see above). For openwebui/coder/
#     golynniis it's because `unrestricted_models = true` resolves to `models = null` (see
#     modules/litellm-virtual-key/key.tf's `local.resolved_models`), not an empty list or a
#     sentinel — `null` is the one config value measured (against a live sandbox proxy, using
#     the real provider, both via fresh create and via `terraform import`) to read back
#     without drift against a key whose `models` field has genuinely never been set, which is
#     exactly what these three keys are. There is no pre-approved exception left: **any** diff
#     on litellm_key.this — on `models` or anything else — means the committed config doesn't
#     match live state. Stop and fix the key-<consumer>.tf file before applying; do not apply
#     a plan that changes this resource without understanding exactly why.
#
#   - bitwarden_secret.apikey: NO changes, once its `value` matches the plaintext already
#     stored in that Bitwarden secret (which it should, since that plaintext IS this key's
#     token).
#
#   - terracurl_request.object_permission: for n8n/openclaw only, WILL show as "1 to add" —
#     this is expected, not a sign of a bad import: it's a brand-new Terraform-only resource
#     with no remote object to adopt (there's nothing meaningful to `terraform import` here —
#     it's a one-shot HTTP call, not an addressable object). Applying it re-POSTs
#     object_permission to values that should already match what's live today, so it's a safe,
#     idempotent no-op against the proxy even though Terraform reports it as a create. For
#     openwebui/coder/golynniis, this resource doesn't exist at all (count = 0 — see
#     object-permission.tf) — those three keys' MCP access stays exactly as untouched as it is
#     today; nothing in this workspace asserts, replicates, or interferes with however they
#     currently get it (see the comment on mcp_server_aliases in modules/litellm-virtual-key/
#     variables.tf).
#
# So: a clean first plan for this workspace means litellm_key and bitwarden_secret show
# nothing at all FOR THESE FIVE — those are the two resources where a surprise change is the actual
# hazard (rotated credential, clobbered secret) — and the only adds attributable to them are the two
# terracurl_request resources for n8n/openclaw.
#
# ------------------------------------------------------------------------------
# THE SIXTH KEY IS NOT PART OF ANY OF THE ABOVE
# ------------------------------------------------------------------------------
#
# obsidian-vault-batch-processor (key-obsidian-vault-batch-processor.tf) has no live counterpart:
# no LiteLLM key carries that alias, no Bitwarden secret carries the generated name, and no
# workload presents it. It is created by apply, and it contributes three adds to the plan —
# litellm_key.this, bitwarden_secret.apikey and terracurl_request.object_permission — which are
# correct and expected, not evidence of a botched import.
#
# What would be evidence of a mistake, in either direction:
#
#   - An `import` block or `terraform import` invocation naming module.obsidian_vault_batch_processor.
#     There is nothing to adopt. Importing it would bind Terraform to whatever key happened to be
#     supplied as the import ID — most plausibly one of the five above — and the next apply would
#     then reconcile that live credential to this key's much narrower config.
#   - A plan showing module.obsidian_vault_batch_processor.litellm_key.this as a CHANGE or REPLACE
#     rather than a create, before the first apply. That means state already holds something for it.
#   - A plan showing any of the five adopted keys as a create. That is the mirror-image failure and
#     rotates a live credential; stop.
#
# The consuming ExternalSecret cannot resolve until this apply has run, so the apply is ordered
# BEFORE the apps repository's reference to the generated Bitwarden name is deployed, never after.

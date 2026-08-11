variable "consumer" {
  description = "Identifier for who/what this key is for (e.g. openwebui, n8n, coder). Used as the litellm_key key_alias, as the terracurl request's name, and to derive the Bitwarden secret name apikey_litellm_<consumer>."
  type        = string
}

# THE EMPTY-MODELS FOOTGUN: LiteLLM coerces an omitted `models` field to `[]`, and then
# treats an empty list as UNRESTRICTED — full access to every model on the proxy
# (auth_checks.py:2877 in LiteLLM v1.93.0: `(len(filtered_models) == 0 and len(models) ==
# 0) or "*" in filtered_models` sets all_model_access = True). There is no key-level "no
# models" sentinel; `no-default-models` is honoured only for *user* objects, never keys.
#
# So "unfilled" and "deliberately unrestricted" must be distinguishable in HCL, and
# neither of the two variables below can do that alone — hence both, plus a precondition
# forcing exactly one to be set (see the `precondition` on `litellm_key.this` in key.tf;
# it CANNOT live here as a `variable "validation"` block because those can't reference
# another variable until Terraform 1.9, and this repo pins 1.6.6 — see key.tf for the
# actual check and why it still fails at plan time). Leaving BOTH unset is an error, not
# a silent "everything": that silent case is the exact footgun this exists to remove.
#
# If a key genuinely needs every model — reproducing the state of a hand-minted key whose
# `models` field was simply never touched, which is what coder/golynniis/openwebui
# actually are today — set `unrestricted_models = true` below. This does NOT translate to
# LiteLLM's `"all-proxy-models"` sentinel; it translates to `null` (see the measured
# evidence in key.tf's `local.resolved_models` — importing a genuinely-untouched key and
# testing candidate config values against it showed `[]` produces a real diff against
# that state, while `null`/omitting the argument is the one value that plans clean). Do
# not reintroduce `"all-proxy-models"` as a valid value of `models` below; the validation
# on `models` blocks it explicitly, since it's a different (if overlapping) representation
# that this module doesn't use and that a live key here has never actually carried.
variable "unrestricted_models" {
  description = "Grant this key every model on the proxy, reproducing a hand-minted key whose models field was never set at all (not a distinct sentinel — see the footgun comment above this variable for the measured reasoning). Mutually exclusive with `models`: set this to true OR set `models` to a non-empty list, never both, never neither — see the precondition in key.tf."
  type        = bool
  default     = false
}

variable "models" {
  description = "Models this key may access, by explicit name. Mutually exclusive with `unrestricted_models = true` — see that variable's description and the footgun comment above it."
  type        = list(string)
  default     = []

  validation {
    condition     = !contains(var.models, "all-proxy-models")
    error_message = "models must not contain the literal string \"all-proxy-models\" — that's LiteLLM's sentinel for unrestricted access, but it is not what this module uses (see the footgun comment above var.unrestricted_models) and not what any live key managed here actually carries. Set unrestricted_models = true instead."
  }
}

# MCP access is an entirely separate gate from `models` above (model checks are never
# invoked on MCP endpoints — the two must stay uncoupled inputs). Unlike models, MCP
# fails CLOSED: a key with no object_permission gets zero servers... for a NON-admin key.
# LiteLLM's own gate (mcp_server_manager.py: get_allowed_mcp_servers) grants every server
# to an admin-role key with no explicit object_permission — a broader, admin-derived
# "everything" that this module does not assert, replicate, or interfere with. So an
# empty/omitted config here means exactly one thing: this module leaves object_permission
# completely untouched, whatever that resolves to for the underlying key. That's also why
# there's no equivalent to the models footgun to guard against: unlike an empty `models`
# list (which IS itself the unrestricted grant), leaving these three variables at their
# defaults doesn't assert zero MCP access — it asserts NOTHING, faithfully reproducing a
# hand-minted key whose object_permission was simply never set (coder, golynniis,
# openwebui today — see their key-<consumer>.tf files). litellm_key itself has no
# object_permission attribute at all (this provider only implements that block on
# litellm_agent), so there's nothing for this module to touch unless the REST seam in
# object-permission.tf actually fires — and it only fires when at least one of these
# three is non-default (see its `count`).
#
# THIS MODULE ONLY IMPLEMENTS THE EXPLICIT SHAPE: bespoke per-key server + tool grants,
# via the object_permission REST seam. There is no separate "broad access" mechanism to
# opt into — broad access is simply the result of never calling this module with any of
# these three set, same as it is for a hand-minted key in the Admin UI.
variable "mcp_server_aliases" {
  description = "MCP servers this key may access, referenced BY ALIAS (or server_name) — never by the server's internal ID. LiteLLM resolves object_permission.mcp_servers entries by alias/server_name as well as by ID, and alias is the only one of those that's stable if a server's URL ever changes, so always pass aliases here."
  type        = list(string)
  default     = []
}

variable "mcp_access_groups" {
  description = "MCP access groups this key belongs to (object_permission.mcp_access_groups) — LiteLLM's string-tag mechanism where a server opts into a named group and a key is granted that group name."
  type        = list(string)
  default     = []
}

variable "mcp_tool_permissions" {
  description = "Per-MCP-server tool allow-lists (object_permission.mcp_tool_permissions), keyed BY ALIAS to match mcp_server_aliases — e.g. { my_server = [\"tool_a\", \"tool_b\"] }. This is ANDed with each server's own allowed_tools/disallowed_tools (owned in the apps repo's Helm values, not here): a tool must be permitted by both to be usable. Genuinely per-key, per-server: two keys granted the same server can and do carry different tool lists here (see openclaw vs n8n in workspaces/litellm/key-openclaw.tf and key-n8n.tf) — this is never a shared profile with overrides."
  type        = map(list(string))
  default     = {}
}

variable "team_id" {
  description = "Team ID associated with this key"
  type        = string
  default     = null
}

variable "max_budget" {
  description = "Maximum budget for this key"
  type        = number
  default     = null
}

variable "budget_duration" {
  description = "Budget reset duration (e.g. '30d', '1h')"
  type        = string
  default     = null
}

variable "tpm_limit" {
  description = "Tokens-per-minute rate limit"
  type        = number
  default     = null
}

variable "rpm_limit" {
  description = "Requests-per-minute rate limit"
  type        = number
  default     = null
}

variable "max_parallel_requests" {
  description = "Maximum parallel requests allowed for this key"
  type        = number
  default     = null
}

variable "duration" {
  description = "Key validity duration (e.g. '30d'). Null means the key never expires"
  type        = string
  default     = null
}

variable "blocked" {
  description = "Whether the key is blocked"
  type        = bool
  default     = null
}

variable "metadata" {
  # DEFAULT MUST BE `null`, NOT `{}` — measured against the sandbox (namespace litellm-audit,
  # kube context sandbox-talos, real ncecere/litellm 2.0.1 provider), 2026-08-11, reproducing
  # the openwebui production import verbatim:
  #
  #   `terraform import` never populates litellm_key's Optional+Computed attributes beyond
  #   id/key (ImportState only sets those two — resource_key.go:397-403); the subsequent Read
  #   leaves every other attribute at its zero value (null) unless the live key already has a
  #   non-empty value for it (readKey's `else if !data.X.IsNull()` reset-to-empty branches never
  #   fire on a freshly-imported, still-null field — resource_key.go:805-1028). So a key whose
  #   live metadata is the (API-rendered) empty object `{}` lands in state as `metadata = null`,
  #   not `metadata = {}` — same "omitted vs. explicit-empty are indistinguishable after the
  #   fact" ambiguity as the `models` footgun below, and resolved the same way: `null` is the
  #   config value that reproduces "never touched," `{}` is a real, different value.
  #
  #   None of litellm_key's Optional+Computed attributes carry a `UseStateForUnknown` plan
  #   modifier (checked against the provider's schema.go — only `id`, `key`, and `key_alias`
  #   do). terraform-plugin-framework's default behavior for a Computed attribute with no
  #   config value is to plan it as Unknown, but ONLY once the resource is undergoing an update
  #   at all — a config that introduces zero genuine diff against imported (mostly-null) state
  #   plans clean with nothing marked unknown. `metadata = {}` here (a known, non-null empty
  #   map) is itself exactly such a genuine diff against the imported `null` state — and that
  #   one spurious diff was enough to flip the ENTIRE resource into "update" mode, cascading
  #   `(known after apply)` onto every other untouched attribute (models, tpm_limit, rpm_limit,
  #   max_budget, aliases, config, permissions, guardrails, prompts, tags, blocked, ...) even
  #   though none of them were actually changing. Reproduced exactly (byte-for-byte identical
  #   plan output shape to the production incident) with `metadata = {}`; switching this default
  #   to `null` produced a genuine "No changes" plan directly after import, no apply needed.
  #
  #   Apply was ALSO verified safe despite the `(known after apply)` noise, independently of
  #   this fix: buildKeyRequest (resource_key.go:478-684) guards every field with
  #   `!data.X.IsUnknown()` before including it in the POST /key/update body, so Unknown fields
  #   are simply omitted from the wire request rather than sent as null/empty — and LiteLLM's
  #   /key/update treats an omitted field as "leave unchanged" (confirmed via GET /key/info
  #   diffed before/after: only the one deliberately-configured field changed, nothing else was
  #   reset). But "safe" isn't the same as "not a permanent diff", which this default fixes.
  #
  # A future consumer that genuinely needs metadata (openclaw/n8n today) still sets this to a
  # real non-null map, transcribed verbatim from `GET /key/info` — see key-openclaw.tf/
  # key-n8n.tf. Empty stays the correct default for a newly-created sixth consumer too: it's
  # what a fresh `litellm_key` with no metadata argument reads back as, so there's nothing
  # inconsistent about a new key defaulting to the same "untouched" representation as the five
  # adopted ones.
  description = "Metadata attached to the key. Values are strings, but the provider (metadata_helpers.go: convertMetadataToNative) treats any value starting with '[' or '{' as JSON and parses it back to a native type before sending to the API — so a live value that's an object or array (e.g. LiteLLM's own tag_rpm_limit: {}) must be given here as jsonencode(...), not a bare string, to round-trip correctly. jsonencode(false)/jsonencode(true) work the same way for booleans (e.g. throttle_on_budget_exceeded). Defaults to null, not {} — see the comment above for why an explicit empty map is a real (if trivial) diff against a freshly-imported key's state, not a no-op."
  type        = map(string)
  default     = null
}

variable "tags" {
  description = "Tags attached to the key"
  type        = list(string)
  default     = null
}

variable "allowed_routes" {
  description = "API routes this key may call (e.g. [\"llm_api_routes\"]). Null/omitted lets LiteLLM apply its own default route set"
  type        = list(string)
  default     = null
}

variable "bitwarden_project_id" {
  description = "Bitwarden Secrets project under which to save this key's plaintext token"
  type        = string
  sensitive   = true
}

variable "note" {
  # DEFAULT MUST BE "", NOT A DESCRIPTIVE TEMPLATE STRING — unlike litellm_key's
  # Optional+Computed attributes above, bitwarden_secret's `note` is schema-REQUIRED
  # (`terraform providers schema -json`: `"note": {"required": true, "type": "string"}`, no
  # `computed` key at all), so it can never be left null/omitted — every apply, import
  # included, must send some string. The five secrets this module adopts already exist with an
  # empty note (confirmed via `bws secret list` against the real Bitwarden project, 2026-08-10:
  # every `apikey_litellm_*` entry's note is ""), so an explicit descriptive default here — the
  # module used to hardcode "LiteLLM virtual key (sk-...) for ${var.consumer}" — is a real,
  # permanent diff against every one of them post-import, same failure shape as the
  # metadata/models defaults above but on a required rather than a computed attribute (so it
  # shows as a genuine `~ note = "" -> "..."` in-place update every single plan, not a
  # transient known-after-apply cascade). The owner's standing instruction is to reproduce live
  # state, not improve on it, so the default is empty to match.
  #
  # A newly-created sixth consumer reads back the same way: a fresh bitwarden_secret with no
  # note argument stores "" too, so defaulting to empty here isn't an inconsistency between
  # adopted and newly-created keys — it's the same "untouched" representation either way. A
  # caller who wants a descriptive note on a new key can still pass one explicitly.
  description = "Note attached to the Bitwarden secret. Required by the bitwarden_secret resource schema (unlike litellm_key's attributes, this cannot be left null), so it always needs a value — defaults to empty to match the five keys imported from hand-minted Bitwarden secrets (confirmed via bws secret list). Pass an explicit string for a new consumer that wants a descriptive note; empty remains a valid, consistent choice there too."
  type        = string
  default     = ""
}

# --- object_permission REST seam inputs (see object-permission.tf) ---

variable "litellm_api_base" {
  description = "Base URL of the LiteLLM proxy (no trailing slash required), used only by the object_permission REST seam to reach POST /key/update directly. The litellm provider itself gets this from the LITELLM_API_BASE env var; terracurl has no such implicit config and needs it passed explicitly."
  type        = string
}

variable "litellm_master_key" {
  description = "LiteLLM proxy master key, used only by the object_permission REST seam to authenticate its direct POST /key/update call (Authorization: Bearer <this>). Never the key created by this module — that plaintext is used solely as the JSON body's `key` identifier, which LiteLLM's API itself requires to know which key to update."
  type        = string
  sensitive   = true
}

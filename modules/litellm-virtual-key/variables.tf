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
  description = "Metadata attached to the key. Values are strings, but the provider (metadata_helpers.go: convertMetadataToNative) treats any value starting with '[' or '{' as JSON and parses it back to a native type before sending to the API — so a live value that's an object or array (e.g. LiteLLM's own tag_rpm_limit: {}) must be given here as jsonencode(...), not a bare string, to round-trip correctly. jsonencode(false)/jsonencode(true) work the same way for booleans (e.g. throttle_on_budget_exceeded)."
  type        = map(string)
  default     = {}
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

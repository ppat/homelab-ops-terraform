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
# If a key genuinely needs every model — including ones that don't exist yet, e.g. a
# future OpenRouter release matched by the proxy's file-declared `openrouter/*` wildcard
# model_list entry — set `unrestricted_models = true` below. LiteLLM's own sentinel for
# this, `SpecialModelNames.all_proxy_models` ("all-proxy-models", litellm/proxy/_types.py)
# is a proxy implementation detail, not something this module's callers should ever have
# to type or recognize — so it appears in exactly one place, the `local.resolved_models`
# translation in key.tf, next to the verification evidence for why it's trusted to stay
# dynamic (source citation + an empirical sandbox result). Do not reintroduce it as a
# valid value of `models` below; the validation on `models` blocks it explicitly.
variable "unrestricted_models" {
  description = "Grant this key every model on the proxy, INCLUDING MODELS THAT DON'T EXIST YET — e.g. a future OpenRouter release matched by the proxy's openrouter/* wildcard becomes reachable through this key with no Terraform change. Mutually exclusive with `models`: set this to true OR set `models` to a non-empty list, never both, never neither — see the footgun comment above this variable and the precondition in key.tf."
  type        = bool
  default     = false
}

variable "models" {
  description = "Models this key may access, by explicit name. Mutually exclusive with `unrestricted_models = true` — see that variable's description and the footgun comment above it."
  type        = list(string)
  default     = []

  validation {
    condition     = !contains(var.models, "all-proxy-models")
    error_message = "models must not contain the literal string \"all-proxy-models\" — that's LiteLLM's internal sentinel for unrestricted access, and this module deliberately keeps it out of its public interface so no call site has to recognize a magic string. Set unrestricted_models = true instead to express \"every model, deliberately\"."
  }
}

# MCP access is an entirely separate gate from `models` above (model checks are never
# invoked on MCP endpoints — the two must stay uncoupled inputs). Unlike models, MCP
# fails CLOSED: a key with no object_permission gets zero servers, so there is no
# equivalent trap to guard against here — an empty/omitted list here is safe and simply
# means "no MCP access", not "all MCP access".
#
# THIS MODULE ONLY IMPLEMENTS THE EXPLICIT/NARROW SHAPE (bespoke per-key server + tool
# grants, via the object_permission REST seam in object-permission.tf). A key that needs
# broad "every self-hosted MCP server, no tool filtering" access instead uses a
# completely separate mechanism that this module deliberately does NOT own: the
# ncecere/litellm `litellm_unified_access_group` resource, composed by the WORKSPACE
# (see workspaces/litellm/virtual-keys.tf), which assigns a key to the group BY ITS
# key_id — an entirely different attachment point from object_permission, requiring none
# of these three variables. The two paths are mutually exclusive by construction: a key
# either passes explicit values here, or gets its key_id added to that shared group, but
# never both (workspaces/litellm/variables.tf validates this). This module has no
# awareness of which path a given key uses — it just does the explicit half correctly.
#
# NAME COLLISION WARNING: `mcp_access_groups` below is LiteLLM's OLDER, string-tag
# mechanism (object_permission.mcp_access_groups; a server opts into a named group via
# its own `mcp_access_groups` field in modules/litellm-mcp-server, and a key opts into
# using that group here) — NOT the `litellm_unified_access_group` resource described
# above, despite both being called "access group" in LiteLLM's own vocabulary. Don't
# conflate them when reading this module or the workspace.
variable "mcp_server_aliases" {
  description = "MCP servers this key may access, referenced BY ALIAS (or server_name) — never by the server's internal ID. LiteLLM resolves object_permission.mcp_servers entries by alias/server_name as well as by ID, and alias is the only one of those that's stable if a server's URL ever changes, so always pass aliases here."
  type        = list(string)
  default     = []
}

variable "mcp_access_groups" {
  description = "MCP access groups this key belongs to (object_permission.mcp_access_groups) — LiteLLM's string-tag mechanism where a server opts into a named group and a key is granted that group name. NOT the litellm_unified_access_group resource (see the NAME COLLISION WARNING above this variable's siblings)."
  type        = list(string)
  default     = []
}

variable "mcp_tool_permissions" {
  description = "Per-MCP-server tool allow-lists (object_permission.mcp_tool_permissions), keyed BY ALIAS to match mcp_server_aliases — e.g. { my_server = [\"tool_a\", \"tool_b\"] }. This is ANDed with each server's own allowed_tools/disallowed_tools (owned in the apps repo's Helm values, not here): a tool must be permitted by both to be usable. Genuinely per-key, per-server: two keys granted the same server can and do carry different tool lists here (see openclaw vs n8n in workspaces/litellm/virtual-keys.tf) — this is never a shared profile with overrides."
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
  description = "Metadata attached to the key"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags attached to the key"
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

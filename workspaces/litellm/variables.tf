# tflint-ignore: terraform_unused_declarations
variable "bitwarden_project_id" {
  type      = string
  sensitive = true
}

# Threaded into every modules/litellm-virtual-key instance's object_permission REST seam
# (see that module's object-permission.tf) — the litellm provider itself gets these from
# the LITELLM_API_BASE/LITELLM_API_KEY env vars, but the seam's terracurl provider has no
# such implicit config and needs them as real Terraform values instead.
variable "litellm_api_base" {
  type = string
}

variable "litellm_master_key" {
  type      = string
  sensitive = true
}

# The catalog backing the "broad MCP access" path (see the litellm_unified_access_group
# resource in virtual-keys.tf) — every self-hosted MCP server alias that a broad-grant key
# should reach, resolved to real server IDs there via the live data.litellm_mcp_servers.all
# data source rather than ever hardcoding a server's internal hash ID (those are derived
# from server_name|url|transport|auth_type|alias and are NOT stable across a URL change —
# see the same reasoning in modules/litellm-mcp-server/mcp-server.tf). default = [] for now
# — populating this with the real current catalog is deferred alongside var.virtual_keys
# below, both pending the owner's confirmation of the all-models sentinel choice.
variable "self_hosted_mcp_server_aliases" {
  type    = list(string)
  default = []
}

# Terraform-managed model additions ONLY. The curated baseline catalog (20 named models +
# an openrouter/* wildcard) stays file-declared in the clusters repo's litellm-model-config
# ConfigMap and is NOT represented here. Map key is the model_name as it will appear to
# clients (e.g. in OpenWebUI) — keep it disjoint from every file-declared model_name; see the
# collision-guard precondition in modules/litellm-model/model.tf.
variable "models" {
  type = map(object({
    custom_llm_provider       = string
    base_model                = string
    model_api_key             = optional(string)
    model_api_base            = optional(string)
    tpm                       = optional(number)
    rpm                       = optional(number)
    tier                      = optional(string)
    mode                      = optional(string)
    additional_litellm_params = optional(map(string), {})
  }))
  default = {}
}

# Remote/SaaS MCP servers ONLY. Self-hosted MCP servers stay file-declared in the apps repo's
# LiteLLM HelmRelease and are NOT represented here. Map key is the server_name. LiteLLM rejects
# "-" in MCP server names/aliases (underscores only) — enforced below. See the collision-guard
# precondition in modules/litellm-mcp-server/mcp-server.tf for why file-declared and
# Terraform-managed names must stay disjoint (a file-declared server always wins name
# resolution over a same-named DB one).
variable "mcp_servers" {
  type = map(object({
    url               = string
    transport         = optional(string, "http")
    alias             = optional(string)
    description       = optional(string)
    auth_type         = optional(string, "none")
    credentials       = optional(map(string), {})
    static_headers    = optional(map(string), {})
    allowed_tools     = optional(list(string))
    mcp_access_groups = optional(list(string))
    allow_all_keys    = optional(bool, false)
  }))
  default = {}

  validation {
    condition     = alltrue([for name in keys(var.mcp_servers) : !strcontains(name, "-")])
    error_message = "MCP server names (map keys) must not contain '-' — LiteLLM rejects hyphens in MCP server names, use underscores instead."
  }

  validation {
    condition     = alltrue([for cfg in values(var.mcp_servers) : cfg.alias == null || !strcontains(cfg.alias, "-")])
    error_message = "MCP server aliases must not contain '-' — LiteLLM rejects hyphens in MCP server names, use underscores instead."
  }
}

# Terraform-managed virtual keys ONLY. Map key is the consumer identifier (openwebui,
# n8n, openclaw, coder, golynniis today) — also used to derive the Bitwarden secret name
# apikey_litellm_<consumer>. default = {} on purpose: none of these five keys' real
# config (models, MCP access) is asserted here yet, since it's being fetched from the
# live proxy separately — see the IMPORT block at the bottom of virtual-keys.tf for how
# each existing hand-minted key gets adopted before its entry here is filled in.
#
# `models` has no default in the object type below and is validated non-empty inside
# modules/litellm-virtual-key itself (see the footgun comment above var.models in that
# module's variables.tf) — every entry added here must set it explicitly. Set it to
# ["all-proxy-models"] (never leave a key with an implicit/empty grant) for a key that's
# genuinely meant to reach every model — see that same comment for why this sentinel
# specifically, and why it stays dynamic instead of freezing today's model list.
#
# `broad_mcp_access`: the OTHER MCP path (see the NAME COLLISION WARNING in
# modules/litellm-virtual-key/variables.tf) — assigns this key to the shared
# litellm_unified_access_group below instead of passing mcp_server_aliases/
# mcp_tool_permissions/mcp_access_groups through to the module. Mutually exclusive with
# those three per the validation below: a key takes the broad path OR the explicit path,
# never both, so it's never ambiguous which one actually granted a given server.
variable "virtual_keys" {
  type = map(object({
    models                = list(string)
    mcp_server_aliases    = optional(list(string), [])
    mcp_access_groups     = optional(list(string), [])
    mcp_tool_permissions  = optional(map(list(string)), {})
    broad_mcp_access      = optional(bool, false)
    team_id               = optional(string)
    max_budget            = optional(number)
    budget_duration       = optional(string)
    tpm_limit             = optional(number)
    rpm_limit             = optional(number)
    max_parallel_requests = optional(number)
    duration              = optional(string)
    blocked               = optional(bool)
    metadata              = optional(map(string), {})
    tags                  = optional(list(string))
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.virtual_keys : !(
        v.broad_mcp_access &&
        (length(v.mcp_server_aliases) > 0 || length(v.mcp_access_groups) > 0 || length(v.mcp_tool_permissions) > 0)
      )
    ])
    error_message = "A virtual_keys entry set broad_mcp_access = true AND at least one of mcp_server_aliases/mcp_access_groups/mcp_tool_permissions. These are mutually exclusive paths to MCP access (broad-grant access group vs. explicit per-server config) — pick one per key, never both, so it's unambiguous which mechanism actually granted a given server."
  }
}

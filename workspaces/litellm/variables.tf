# tflint-ignore: terraform_unused_declarations
variable "bitwarden_project_id" {
  type      = string
  sensitive = true
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

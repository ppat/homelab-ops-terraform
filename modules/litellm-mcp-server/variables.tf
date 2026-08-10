variable "server_name" {
  description = "MCP server name. Must be disjoint from every file-declared server_name/alias in the apps repo's LiteLLM HelmRelease — see the collision-guard precondition in mcp-server.tf. LiteLLM rejects '-' in MCP server names (underscores only); the calling workspace validates this across all server_name/alias values before this module is instantiated."
  type        = string
}

variable "alias" {
  description = "Optional MCP server alias, checked by the same collision guard as server_name"
  type        = string
  default     = null
}

variable "description" {
  description = "Human-readable description of the MCP server"
  type        = string
  default     = null
}

variable "url" {
  description = "URL of the remote/SaaS MCP server"
  type        = string
}

variable "transport" {
  description = "MCP transport protocol"
  type        = string
  default     = "http"
}

variable "auth_type" {
  description = "MCP server authentication type"
  type        = string
  default     = "none"
}

variable "credentials" {
  description = "Credentials used to authenticate to the MCP server"
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "static_headers" {
  description = "Static headers sent on every request to the MCP server"
  type        = map(string)
  default     = {}
}

variable "allowed_tools" {
  description = "Allow-list of tool names exposed from this MCP server. Null means no allow-list is applied"
  type        = list(string)
  default     = null
}

variable "mcp_access_groups" {
  description = "Access groups permitted to use this MCP server"
  type        = list(string)
  default     = null
}

variable "allow_all_keys" {
  description = "Whether all virtual keys may access this MCP server"
  type        = bool
  default     = false
}

variable "existing_mcp_servers" {
  description = "Full result of the calling workspace's litellm_mcp_servers data source (data.litellm_mcp_servers.all.mcp_servers) — both file- and DB-declared servers. Consumed only by the collision-guard precondition below to detect a name/alias collision with a file-declared server; not used to build the resource itself."
  type        = any
}

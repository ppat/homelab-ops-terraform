# ============================================================================
# SEAM — object_permission via direct REST call. DELETE THIS FILE WHOLESALE
# once ncecere/litellm exposes object_permission on litellm_key natively.
# ============================================================================
#
# The gap: ncecere/litellm v2.0.1's litellm_key resource does not expose
# `object_permission` (checked against the provider's own Terraform schema —
# `terraform providers schema -json` shows litellm_key has no block_types at
# all). LiteLLM's proxy API supports it fully: accepted on both
# POST /key/generate and POST /key/update, and readable back via
# GET /key/info. This same provider already implements the identical
# object_permission block end-to-end on its litellm_agent resource (see that
# resource's schema: object_permission.{models,mcp_servers,
# mcp_access_groups,mcp_tool_permissions,agents}) — so this is a provider
# gap on the wrong resource, not a LiteLLM limitation, and not something that
# needs an upstream PR or a fork to work around here: it needs one more
# resource wired up on their end.
#
# The bridge: one terracurl_request that PATCHes object_permission onto the
# key litellm_key.this already created, by POSTing directly to the proxy's
# own /key/update endpoint — the same endpoint the provider itself will
# presumably call internally once it grows support for this field. This is
# the ONLY place in the module that talks to the proxy outside the litellm
# provider, and the only place that touches the terracurl provider — nothing
# else in this module depends on this file, and nothing in this file is
# depended on by anything outside it (outputs.tf does not reference it).
# Deleting this file, the `terracurl` entry in terraform.tf's
# required_providers, and the litellm_api_base/litellm_master_key variables
# is the entire removal — then move object_permission_* config straight onto
# litellm_key.this in key.tf.
#
# Secret hygiene: GET /key/info never returns a key's plaintext token, only a
# hash — so this resource must never try to read the key back to reconcile
# it (that would require guessing/re-deriving the plaintext, which isn't
# possible, or worse, silently rotating it). The only plaintext this module
# ever sees is litellm_key.this.key, returned once at creation. Below, that
# plaintext is used only as the JSON body's `key` field — LiteLLM's own API
# requires it there to identify which key to update, there is no by-hash
# update endpoint. It is never interpolated into `url` or `headers`, and
# because litellm_key.this.key is `sensitive = true` in the provider schema,
# the whole `request_body` expression inherits that sensitivity: Terraform
# redacts it in plan/apply output as "(sensitive value)" even though the
# terracurl provider's own `request_body` attribute isn't itself marked
# sensitive in its schema. Authentication for this call is the proxy MASTER
# key (var.litellm_master_key) — never the virtual key being updated.
#
# Only fires when there's actually something explicit to set: a key using the OTHER,
# broad-grant path (assignment to a litellm_unified_access_group — see the NAME
# COLLISION WARNING in variables.tf) leaves mcp_server_aliases/mcp_access_groups/
# mcp_tool_permissions at their empty defaults, and for that key we deliberately do
# NOTHING here rather than actively POST an explicit-empty object_permission. A
# freshly-created litellm_key already has object_permission = null — the verified-safe
# "zero MCP" default (see the fails-CLOSED comment on mcp_server_aliases) — and leaving
# it untouched is strictly safer than writing an equivalent-looking explicit empty object
# whose interaction with a separate unified-access-group assignment isn't something this
# module has verified.
resource "terracurl_request" "object_permission" {
  count = (
    length(var.mcp_server_aliases) > 0 ||
    length(var.mcp_access_groups) > 0 ||
    length(var.mcp_tool_permissions) > 0
  ) ? 1 : 0

  name   = "litellm-key-${var.consumer}-object-permission"
  method = "POST"
  url    = "${trimsuffix(var.litellm_api_base, "/")}/key/update"

  headers = {
    "Content-Type"  = "application/json"
    "Authorization" = "Bearer ${var.litellm_master_key}"
  }

  request_body = jsonencode({
    key = litellm_key.this.key
    object_permission = {
      mcp_servers          = var.mcp_server_aliases
      mcp_access_groups    = var.mcp_access_groups
      mcp_tool_permissions = var.mcp_tool_permissions
    }
  })

  response_codes = ["200"]

  # No read-based drift detection: the only source of truth this module
  # recognizes is its own config, and a spurious drift-triggered replace here
  # would just re-issue the same idempotent POST anyway. Keeping this off
  # avoids that noise without losing any real safety.
  skip_read = true

  # This call only ever pushes state forward — a change to any of the
  # mcp_* variables replaces this resource (terracurl has no in-place update;
  # changing request_body forces a destroy-then-create), and because
  # POST /key/update is idempotent, "create-again with a new body" IS the
  # correct reconciliation, not a hazard. What must never happen is this
  # resource trying to UNDO the key's object_permission when the resource
  # itself is destroyed/replaced (e.g. during the destroy half of that
  # replace cycle, or if this key is ever decommissioned) — object_permission
  # is the litellm_key resource's own field to own the lifecycle of, not this
  # seam's, so the destroy call is disabled outright rather than left to
  # default behavior.
  skip_destroy = true

  # mcp_tool_permissions keys must be a subset of mcp_server_aliases: a tool
  # permission for a server this key can't even reach is a silent no-op that
  # looks like it does something. Catch that here, at the one place both
  # variables are actually used together.
  lifecycle {
    precondition {
      condition     = alltrue([for alias in keys(var.mcp_tool_permissions) : contains(var.mcp_server_aliases, alias)])
      error_message = "mcp_tool_permissions references a server alias not present in mcp_server_aliases for consumer '${var.consumer}' — a tool permission for a server this key can't access is a silent no-op. Add the alias to mcp_server_aliases or remove it from mcp_tool_permissions."
    }
  }
}

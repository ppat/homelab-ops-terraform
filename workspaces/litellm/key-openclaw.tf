# openclaw: BLOCKED, not yet written. This key needs 8 explicit models and bespoke
# mcp_tool_permissions across 5 servers (context7, playwright, grafana, home_assistant,
# github — aliases confirmed by hash computation against the live proxy). The owner-supplied
# live-key-inventory only gives COUNTS and abbreviated examples for those two fields (e.g.
# "8 explicit models", "grafana: query_prometheus, list_datasources, ..." with an elision, "far
# broader than n8n's — includes incidents, athena/clickhouse/snowflake, sift, oncall") — not the
# verbatim lists this file needs. Writing this module block with anything less than the exact
# live values would mean guessing an access-control list for a live credential, which is the
# exact failure class this whole design exists to prevent (a wrong tool grant is just as bad as
# a dropped one). Needed from the owner: the 8 model names, and each of the 5 servers' complete
# tool list, exactly as granted today (GET /key/info for this key, object_permission.
# mcp_tool_permissions). Once supplied, this becomes a module "openclaw" block identical in
# shape to key-n8n.tf's (once that's filled in too), with its own bespoke values — see
# modules/litellm-virtual-key/variables.tf's comment on mcp_tool_permissions for why these two
# keys' tool lists are never a shared profile with overrides.

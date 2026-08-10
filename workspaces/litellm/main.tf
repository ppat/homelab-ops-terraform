# Shared data sources for the collision guard used by both models.tf and mcp-servers.tf:
# reading the full inventory once and filtering it per-resource in a lifecycle precondition,
# rather than re-querying per for_each key.
data "litellm_models" "all" {}

data "litellm_mcp_servers" "all" {}

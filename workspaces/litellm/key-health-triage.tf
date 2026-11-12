# health-triage: the homelab cluster health check's diagnosis step, an n8n workflow (Health Diagnose,
# in homelab-ops-kubernetes-clusters clusters/homelab/services/ai/n8n/workflows). Created by
# Terraform, not adopted: nothing presents this key until the workflow's credential is wired, so the
# first apply rotates nothing.
#
# The consumer string resolves to:
#
#   gateway key_alias  health-triage
#   Bitwarden secret   apikey_litellm_healthtriage
#
# The clusters repository's n8n-workflow-secrets ExternalSecret quotes that Bitwarden name exactly;
# renaming this consumer later is a destroy-and-recreate of a live credential.
#
# Separate from the n8n key on purpose. Diagnosis is an LLM loop with tool access, so it gets its own
# spend cap that fails closed when exhausted, and an MCP grant limited to the read-only calls the
# workflow's tool wrappers make. A broader key here would let a prompt-injected diagnosis reach tools
# the wrappers never expose.
module "health_triage" {
  source = "../../modules/litellm-virtual-key"

  consumer            = "health-triage"
  unrestricted_models = true

  # The workflow's tool wrappers call exactly these MCP tools; anything else is refused here too.
  mcp_server_aliases = [
    "grafana",
    "kubernetes_homelab",
    "kubernetes_nas",
  ]
  mcp_tool_permissions = {
    grafana = [
      "query_prometheus",
      "query_loki_logs",
    ]
    kubernetes_homelab = [
      "resources_get",
      "resources_list",
      "events_list",
      "pods_log",
    ]
    kubernetes_nas = [
      "resources_get",
      "resources_list",
      "events_list",
      "pods_log",
    ]
  }

  # Chat completions and /mcp-rest/tools/call are both in LiteLLM's llm_api_routes group.
  allowed_routes = ["llm_api_routes"]

  max_budget      = 10
  budget_duration = "30d"

  note = "LiteLLM virtual key for the homelab health check's diagnosis workflow in n8n; openai/gpt-mini-latest only, read-only grafana and kubernetes MCP tools, 10 USD per 30 days"

  bitwarden_project_id = var.bitwarden_project_id
  litellm_api_base     = var.litellm_api_base
  litellm_master_key   = var.litellm_master_key
}

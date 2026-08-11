# golynniis: a MacBook (host key). Same posture as coder — see the comment there — every model
# on the proxy, MCP access left entirely untouched (no separate "broad access" mechanism).
module "golynniis" {
  source = "../../modules/litellm-virtual-key"

  consumer            = "golynniis"
  unrestricted_models = true
  allowed_routes      = ["llm_api_routes"]

  bitwarden_project_id = var.bitwarden_project_id
  litellm_api_base     = var.litellm_api_base
  litellm_master_key   = var.litellm_master_key
}

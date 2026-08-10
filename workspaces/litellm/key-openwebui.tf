# openwebui: chat UI. Every model on the proxy (deliberately — see the footgun comment on
# var.unrestricted_models in modules/litellm-virtual-key/variables.tf), no MCP access at all —
# openwebui never presents tool-using requests, so it stays at the module's default (zero
# servers, object_permission left untouched — see object-permission.tf in that module).
module "openwebui" {
  source = "../../modules/litellm-virtual-key"

  consumer            = "openwebui"
  unrestricted_models = true

  bitwarden_project_id = var.bitwarden_project_id
  litellm_api_base     = var.litellm_api_base
  litellm_master_key   = var.litellm_master_key
}

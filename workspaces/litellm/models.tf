# Terraform-managed model additions ONLY — one modules/litellm-model instance per var.models
# entry. The curated baseline catalog stays file-declared in the clusters repo and is not
# represented here. How each model is built and guarded against colliding with that file-
# declared catalog lives in the module; this file only says which models exist.
module "model" {
  source = "../../modules/litellm-model"

  for_each = var.models

  model_name          = each.key
  custom_llm_provider = each.value.custom_llm_provider
  base_model          = each.value.base_model
  model_api_key       = each.value.model_api_key
  model_api_base      = each.value.model_api_base
  tpm                 = each.value.tpm
  rpm                 = each.value.rpm
  tier                = each.value.tier
  mode                = each.value.mode

  additional_litellm_params = each.value.additional_litellm_params

  existing_models = data.litellm_models.all.models
}

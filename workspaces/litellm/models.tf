# Terraform-managed model additions ONLY. The curated baseline catalog stays file-declared in
# the clusters repo and is not represented here. There are zero Terraform-managed models
# today. When one is needed, add a concrete instance here — NOT a map variable — following
# the instance pattern in workspaces/minio-nas/bucket-*.tf:
#
# module "some_model_name" {
#   source = "../../modules/litellm-model"
#
#   model_name          = "some_model_name"
#   custom_llm_provider = "..."
#   base_model          = "..."
#
#   existing_models = data.litellm_models.all.models
# }
#
# One module block per model, real config committed inline — see main.tf for the shared
# data.litellm_models.all this and every future instance's collision guard reads from.

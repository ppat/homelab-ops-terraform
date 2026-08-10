# Collision guard rationale (see also mcp-servers.tf):
#
# The hazard: nothing in LiteLLM enforces disjoint model_name between the file-declared
# catalog (clusters repo litellm-model-config ConfigMap) and DB-declared models (this
# workspace). A duplicate model_name doesn't error — it silently becomes a second
# deployment in the same load-balancing pool, so a Terraform model reusing a curated name
# would quietly absorb a share of that model's traffic instead of failing loudly.
#
# The ideal guard would filter the ncecere/litellm provider's `litellm_models` data source
# down to file-declared entries via the `db_model` flag that LiteLLM's own /v1/model/info
# API returns. That flag is NOT exposed by the data source's schema (see
# internal/provider/datasource_models_list.go in the provider source — ModelListItem has
# id/model_name/custom_llm_provider/base_model/tier/mode/team_id, no db_model), so we fall
# back to the next-best signal that IS exposed: the shape of `id`.
#   - File-declared models get LiteLLM's internal stable hash of model_name+litellm_params
#     as their id (llm_router._generate_model_id) — never a UUID.
#   - Every DB-declared model gets a real UUID: this provider's own resource_model.go
#     generates one client-side with uuid.New() and sends it as model_info.id/db_model=true
#     on create; hand-created (Admin UI) models get Prisma's `@default(uuid())`.
# So "id is not UUID-shaped" is a reliable proxy for "file-declared" here. It also sidesteps
# the alternative of comparing against this resource's own id: that would need to exclude a
# not-yet-known id during the very first create, which either can't be evaluated at plan time
# or degenerates into a postcondition-after-the-fact check. Filtering by id *shape* needs no
# self-reference at all, so it works identically on first create and every later plan.
#
# Trade-off: this only catches collisions with entries that still look DB-managed today. If a
# future LiteLLM/provider version changes file-model id generation to UUIDs, this guard goes
# blind silently — revisit if `db_model` ever becomes an exposed data source field.
resource "litellm_model" "this" {
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

  lifecycle {
    precondition {
      condition = length([
        for m in data.litellm_models.all.models : m
        if m.model_name == each.key && !can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", m.id))
      ]) == 0
      error_message = "model_name '${each.key}' already exists as a file-declared model in the clusters repo's litellm-model-config ConfigMap. A duplicate name silently joins that model's load-balancing pool instead of failing loudly — rename this Terraform model to a name not used by the curated catalog."
    }
  }
}

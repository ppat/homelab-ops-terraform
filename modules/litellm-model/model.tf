# Collision guard rationale (see also modules/litellm-mcp-server/mcp-server.tf):
#
# The hazard: nothing in LiteLLM enforces disjoint model_name between the file-declared
# catalog (clusters repo litellm-model-config ConfigMap) and DB-declared models (this
# module). A duplicate model_name doesn't error — it silently becomes a second
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
#
# The discriminator's own liveness (is "id is not UUID-shaped" still classifying anything as
# file-declared at all) is not this module's concern — it's a property of the discriminator
# shared by every model and MCP server, not of any one object, so it's checked once at the
# workspace level (see the `check` blocks in workspaces/litellm/main.tf) against the raw data
# source this module receives via var.existing_models.
resource "litellm_model" "this" {
  model_name          = var.model_name
  custom_llm_provider = var.custom_llm_provider
  base_model          = var.base_model
  model_api_key       = var.model_api_key
  model_api_base      = var.model_api_base
  tpm                 = var.tpm
  rpm                 = var.rpm
  tier                = var.tier
  mode                = var.mode

  additional_litellm_params = var.additional_litellm_params

  lifecycle {
    precondition {
      condition = length([
        for m in var.existing_models : m
        if m.model_name == var.model_name && !can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", m.id))
      ]) == 0
      error_message = "model_name '${var.model_name}' already exists as a file-declared model in the clusters repo's litellm-model-config ConfigMap. A duplicate name silently joins that model's load-balancing pool instead of failing loudly — rename this Terraform model to a name not used by the curated catalog."
    }
  }
}

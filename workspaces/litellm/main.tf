# Shared data sources for the collision guard used by every modules/litellm-model and
# modules/litellm-mcp-server instance below: reading the full inventory once here and passing
# it into each module call as var.existing_models / var.existing_mcp_servers, rather than each
# module instance re-querying it independently for every for_each key.
data "litellm_models" "all" {}

data "litellm_mcp_servers" "all" {}

# Liveness checks for the collision guard's discriminator itself (see the id-shape heuristic
# explained in modules/litellm-model/model.tf and modules/litellm-mcp-server/mcp-server.tf).
# These live here, at the workspace level, rather than inside either module: the discriminator
# is a property of the data sources themselves, shared by every model and MCP server, not of
# any one object — duplicating it as a `check` block inside each of the N per-object module
# instances below would just repeat the identical assertion N times over the same data.
#
# These are deliberately separate `check` blocks, not folded into the per-resource
# preconditions living in the modules: "does this specific name collide" and "is the
# file-vs-DB discriminator still able to tell the difference" are different questions. The
# preconditions answer the first and only run per module instance; these answer the second and
# only need to run once each, against the raw data sources.
#
# Why this needs its own check: the discriminator has no signal for its own correctness. If a
# future LiteLLM or ncecere/litellm provider version starts giving file-declared entries
# UUID-shaped ids too (the same shape DB-declared entries already use), every precondition
# above keeps evaluating and keeps passing — just against a file-declared partition that quietly
# became empty. The guard would look green while protecting nothing, which is exactly the
# silent-failure class it exists to prevent in the first place.
#
# The catch: the production baseline is never empty. The clusters repo currently declares 20
# file-declared models (plus an openrouter/* wildcard) and the apps repo declares 12
# file-declared MCP servers. So whenever a data source returns any entries at all, at least one
# of them should classify as file-declared; if none do, the "id is not UUID-shaped" heuristic
# itself has broken, not the world. Deliberately checking only for "empty" rather than "fewer
# than N" — hardcoding today's catalog size would make this check fire on every legitimate
# catalog resize upstream, which is its own path to getting ignored/disabled.
#
# `check`, not `precondition`, on purpose: a false positive here (e.g. a sandbox/dev LiteLLM
# instance seeded with only Terraform-managed entries and no file-declared baseline at all)
# would otherwise hard-fail every apply of every model and MCP server — for a condition that,
# per the reasoning above, already leaves the real collision-guard preconditions silently
# passing rather than failing closed. A hard failure here buys no additional safety over the
# preconditions already going quiet, but does create an incentive to bypass or disable the
# check the first time it's wrong. A warning stays visible in every plan without blocking work.
check "models_collision_guard_discriminator_live" {
  assert {
    condition = (
      length(data.litellm_models.all.models) == 0 ||
      length([
        for m in data.litellm_models.all.models : m
        if !can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", m.id))
      ]) > 0
    )
    error_message = "The models collision guard's file-vs-DB discriminator (id-shape heuristic, see modules/litellm-model/model.tf) classified ZERO of the entries returned by data.litellm_models.all as file-declared, even though entries exist. The file-declared catalog is not supposed to be empty (20+ curated models normally live in the clusters repo's litellm-model-config ConfigMap), so this means the discriminator itself has stopped working, not that the catalog emptied out. The collision guard is no longer protecting anything against file-declared name collisions — re-verify the id-shape assumption (llm_router._generate_model_id vs this provider's resource_model.go uuid.New()) against the current LiteLLM and provider versions before trusting it again."
  }
}

check "mcp_servers_collision_guard_discriminator_live" {
  assert {
    condition = (
      length(data.litellm_mcp_servers.all.mcp_servers) == 0 ||
      length([
        for s in data.litellm_mcp_servers.all.mcp_servers : s
        if !can(regex("^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$", s.server_id))
      ]) > 0
    )
    error_message = "The MCP server collision guard's file-vs-DB discriminator (id-shape heuristic, see modules/litellm-mcp-server/mcp-server.tf) classified ZERO of the entries returned by data.litellm_mcp_servers.all as file-declared, even though entries exist. The file-declared catalog is not supposed to be empty (12 self-hosted MCP servers normally live in the apps repo's LiteLLM HelmRelease), so this means the discriminator itself has stopped working, not that the catalog emptied out. The collision guard is no longer protecting anything against file-declared name collisions — re-verify the id-shape assumption against the current LiteLLM and provider versions before trusting it again."
  }
}

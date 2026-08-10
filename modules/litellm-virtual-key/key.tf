locals {
  # THE ONLY PLACE "all-proxy-models" APPEARS IN THIS MODULE. LiteLLM's own sentinel for
  # "every model on the proxy" (SpecialModelNames.all_proxy_models,
  # litellm/proxy/_types.py) — deliberately kept out of this module's public interface
  # (var.models rejects it outright; var.unrestricted_models is how a caller expresses
  # the same intent without needing to know or type this string).
  #
  # Trusted to stay DYNAMIC rather than a point-in-time snapshot, verified two ways
  # against LiteLLM v1.93.0:
  #   - Source: key_management_endpoints.py writes the `models` list straight into the DB
  #     verbatim (no expansion at /key/generate or /key/update time), and
  #     auth_checks.py's `_check_model_access_helper` — invoked on every single request
  #     via user_api_key_auth.py, the main auth middleware — re-checks that literal
  #     string against whatever model was just requested. So a model that didn't exist
  #     when this key was created is reachable the moment it's added to the router, with
  #     no Terraform change.
  #   - Empirical: against a live sandbox proxy, a key with models=["all-proxy-models"]
  #     calling a model name that exists nowhere in the router got the proxy's
  #     *router*-level "Invalid model name" error (400) — never the *key-access* "key not
  #     allowed to access model" / key_model_access_denied error (403) that an
  #     explicitly-scoped key gets for the identical call. That's proof the access GATE
  #     itself was passed regardless of whether the model was known at key-creation time;
  #     the 400 only means the sandbox's router had nothing registered under that name.
  resolved_models = var.unrestricted_models ? ["all-proxy-models"] : var.models
}

# `prevent_destroy`: the five keys this module exists to manage are ADOPTED (imported),
# not created fresh — each is a live credential a real consumer is already presenting to
# the gateway. A replace (destroy+recreate) here would rotate that credential out from
# under its consumer with zero warning beyond a plan diff someone has to actually read.
# Recreation must never happen as a side effect of an unrelated change; if this key
# really needs to be destroyed, that has to be a deliberate act — remove this line
# first, on purpose, in its own change.
resource "litellm_key" "this" {
  key_alias = var.consumer
  models    = local.resolved_models

  team_id               = var.team_id
  max_budget            = var.max_budget
  budget_duration       = var.budget_duration
  tpm_limit             = var.tpm_limit
  rpm_limit             = var.rpm_limit
  max_parallel_requests = var.max_parallel_requests
  duration              = var.duration
  blocked               = var.blocked
  metadata              = var.metadata
  tags                  = var.tags

  lifecycle {
    prevent_destroy = true

    # THE XOR CHECK. Can't be a `variable "validation"` on var.models (cross-variable
    # references in variable validation blocks require Terraform >= 1.9; this repo pins
    # 1.6.6 — see modules/litellm-model/model.tf for the precedent of using a resource
    # precondition here instead, referencing var.existing_models the same way). A
    # resource `precondition` has existed since Terraform 1.2 and, because both operands
    # here are plain input variables (known before any provider is ever contacted, not
    # values computed from a resource or data source), Terraform evaluates it during
    # planning — this fails the `terraform plan`, not the apply.
    #
    # LiteLLM treats an empty (or omitted) `models` list on a virtual key as
    # UNRESTRICTED — full access to every model on the proxy; there is no key-level
    # deny-all. Leaving both unrestricted_models and models unset here would silently
    # produce that exact same unrestricted grant, which is the footgun this whole
    # variable pair exists to remove — so neither "both set" nor "neither set" is
    # allowed, only exactly one.
    precondition {
      condition     = var.unrestricted_models != (length(var.models) > 0)
      error_message = "Exactly one of unrestricted_models or models must be set for consumer '${var.consumer}'. LiteLLM treats an empty (or omitted) models list on a virtual key as UNRESTRICTED access to every model on the proxy — there is no key-level deny-all — so leaving both unset here would silently grant everything. Set unrestricted_models = true to deliberately grant every model (including ones that don't exist yet), or set models to an explicit non-empty list. Never both, never neither."
    }
  }
}

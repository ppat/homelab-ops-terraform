locals {
  # var.unrestricted_models must resolve to whatever config value produces a CLEAN plan
  # against a live key that has no models restriction — which is how coder/golynniis/
  # openwebui actually exist today (hand-minted in the Admin UI with the models field
  # never touched at all). This is `null`, not `[]` — measured, not assumed, against a
  # live sandbox proxy (namespace litellm-audit, kube context sandbox-talos) using the
  # real ncecere/litellm provider, 2026-08-10:
  #
  #   1. Two keys created via the raw API: one with `models` omitted from the JSON body
  #      entirely, one with `"models": []` explicit. GET /key/info renders BOTH
  #      identically as `"models": []` — the API's rendering does not distinguish
  #      "omitted" from "explicit empty" after the fact, so it can't tell you what config
  #      value to use.
  #   2. `terraform import`ing each into a bare `litellm_key` resource (no `models` in
  #      config) and inspecting `terraform show -json`: the provider's Read populates
  #      `models` as `null` in state for BOTH — not `[]` — because its Read logic
  #      (resource_key.go) only fills in an empty-list value when the incoming state
  #      already held a non-null list (i.e. on a fresh create from config that specified
  #      `models = []`); on import there's no such prior value, so it stays null.
  #   3. Plan against that imported (null) state: `models = []` in config produced a real
  #      diff (`1 to change`, null -> []) — NOT a clean plan. `models = null` and omitting
  #      the argument entirely both produced "No changes." Confirmed both directions:
  #      importing into null-state config and fresh-creating with `models = null` (which
  #      then reads back as null and stays clean on every subsequent plan) both work.
  #
  # So `[]` is the API's rendering of "no restriction", but `null` is the one Terraform
  # config value that reproduces "this key's models field has never been touched" without
  # asserting a value the live key doesn't actually have set.
  resolved_models = var.unrestricted_models ? null : var.models
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
  allowed_routes        = var.allowed_routes

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
    # LiteLLM treats an empty (or omitted/null) `models` list on a virtual key as
    # UNRESTRICTED — full access to every model on the proxy; there is no key-level
    # deny-all. Leaving both unrestricted_models and models unset here would silently
    # produce that exact same unrestricted grant, which is the footgun this whole
    # variable pair exists to remove — so neither "both set" nor "neither set" is
    # allowed, only exactly one. (var.models itself still defaults to `[]`, never
    # `null` — the null case only ever happens via local.resolved_models above, once
    # unrestricted_models has already been deliberately set to true.)
    precondition {
      condition     = var.unrestricted_models != (length(var.models) > 0)
      error_message = "Exactly one of unrestricted_models or models must be set for consumer '${var.consumer}'. LiteLLM treats an empty (or omitted) models list on a virtual key as UNRESTRICTED access to every model on the proxy — there is no key-level deny-all — so leaving both unset here would silently grant everything. Set unrestricted_models = true to deliberately grant every model (including ones that don't exist yet), or set models to an explicit non-empty list. Never both, never neither."
    }
  }
}

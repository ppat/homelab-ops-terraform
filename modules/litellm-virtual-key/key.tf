# `models` is guaranteed non-empty by var.models' own `validation` block (see
# variables.tf) — LiteLLM treats [] the same as an omitted field, and both mean
# unrestricted access to every model on the proxy. Never widen that validation or add a
# fallback default here that could hand this resource an empty list.
#
# `prevent_destroy`: the five keys this module exists to manage are ADOPTED (imported),
# not created fresh — each is a live credential a real consumer is already presenting to
# the gateway. A replace (destroy+recreate) here would rotate that credential out from
# under its consumer with zero warning beyond a plan diff someone has to actually read.
# Recreation must never happen as a side effect of an unrelated change; if this key
# really needs to be destroyed, that has to be a deliberate act — remove this line
# first, on purpose, in its own change.
resource "litellm_key" "this" {
  key_alias = var.consumer
  models    = var.models

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
  }
}

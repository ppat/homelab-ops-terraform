variable "actions_secrets" {
  type    = map(string)
  default = {}
}

variable "actions_variables" {
  type    = map(string)
  default = {}
}

variable "actions_allowed" {
  type    = list(string)
  default = []
}

variable "environment_secrets" {
  description = "Map of environment names to their secrets (secret_name -> secret_value)"
  type        = map(map(string))
  default     = {}
}

variable "force_push_bypassers" {
  type    = list(string)
  default = []
}

variable "homepage_url" {
  type    = string
  default = ""
}

variable "main_ruleset_enabled" {
  description = "Create a ruleset on the default branch requiring changes to arrive via pull request. Off by default; repositories opt in one at a time."
  type        = bool
  default     = false
}

variable "main_ruleset_required_approving_review_count" {
  description = "Approvals required by the ruleset's pull_request rule. Must be >= 1 to stop a write actor merging its own PRs; 0 makes the rule decorative (measured, see ruleset.tf)."
  type        = number
  default     = 1
}

variable "main_ruleset_bypass_actors" {
  description = "Actors exempt from the ruleset (NOT from classic branch protection -- measured, see ruleset.tf). RepositoryRole admin is actor_id 5. For Integration, actor_id is the GitHub App id."
  type = list(object({
    actor_id    = number
    actor_type  = string
    bypass_mode = string
  }))
  default = []
}

variable "repository" {
  type = object({
    name        = string
    description = string
    visibility  = string
  })
}

variable "require_signed_commits" {
  type    = bool
  default = true
}

variable "required_status_checks" {
  type    = list(string)
  default = []
}

variable "required_status_checks_strict" {
  type    = bool
  default = true
}

variable "topics" {
  type    = list(string)
  default = []
}

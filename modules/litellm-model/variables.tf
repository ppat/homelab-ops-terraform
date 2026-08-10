variable "model_name" {
  description = "Model name as it will appear to clients (e.g. in OpenWebUI). Must be disjoint from every file-declared model_name in the clusters repo's litellm-model-config ConfigMap — see the collision-guard precondition in model.tf."
  type        = string
}

variable "custom_llm_provider" {
  description = "LiteLLM custom_llm_provider for this model (e.g. openai, azure, bedrock)"
  type        = string
}

variable "base_model" {
  description = "Underlying model identifier passed to the upstream provider"
  type        = string
}

variable "model_api_key" {
  description = "API key for the upstream provider, if required"
  type        = string
  default     = null
  sensitive   = true
}

variable "model_api_base" {
  description = "API base URL for the upstream provider, if required"
  type        = string
  default     = null
}

variable "tpm" {
  description = "Tokens-per-minute rate limit"
  type        = number
  default     = null
}

variable "rpm" {
  description = "Requests-per-minute rate limit"
  type        = number
  default     = null
}

variable "tier" {
  description = "LiteLLM pricing/routing tier"
  type        = string
  default     = null
}

variable "mode" {
  description = "LiteLLM model mode (e.g. chat, completion, embedding)"
  type        = string
  default     = null
}

variable "additional_litellm_params" {
  description = "Additional litellm_params merged into the model's configuration"
  type        = map(string)
  default     = {}
}

variable "existing_models" {
  description = "Full result of the calling workspace's litellm_models data source (data.litellm_models.all.models) — both file- and DB-declared models. Consumed only by the collision-guard precondition below to detect a name collision with a file-declared model; not used to build the resource itself."
  type        = any
}

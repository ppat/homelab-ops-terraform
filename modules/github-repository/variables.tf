variable "actions_secrets" {
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

variable "repository" {
  type = object({
    name        = string
    description = string
    visibility  = string
  })
}

variable "required_status_checks" {
  type    = list(string)
  default = []
}

variable "topics" {
  type    = list(string)
  default = []
}

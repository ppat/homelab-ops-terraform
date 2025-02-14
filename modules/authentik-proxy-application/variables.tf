variable "application_url" {
  description = "External URL for the application"
  type        = string
}

variable "flows" {
  description = "Authentik flows"
  type = object({
    authentication = string
    authorization  = string
    invalidation   = string
  })
}

variable "groups" {
  description = "Groups to be bound to this application"
  type        = list(string)
}

variable "launch_url" {
  description = "Launch URL for the app"
  type        = string
  default     = ""
}

variable "name" {
  description = "app name"
  type        = string
}

variable "icon_url" {
  description = "app icon"
  type        = string
  default     = ""
}

variable "property_mappings" {
  description = "OAuth2 Scope mappings"
  type        = list(string)
}

variable "unauthenticated_paths_regex" {
  description = "Skip auth for paths matching this regex"
  type        = string
  default     = ""
}

variable "validity" {
  description = "Expiration/Validity for tokens"
  type = object({
    access_token  = string
    refresh_token = string
  })
  default = {
    access_token  = "hours=1"
    refresh_token = "hours=4"
  }
}

variable "bitwarden_project_id" {
  description = "Bitwarden Secrets project under which to save the owner's access and secret keys"
  type        = string
  sensitive   = true
}

variable "client_id" {
  description = "OIDC client ID"
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
  description = "Groups to be bound to this Authentik application"
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

variable "redirect_uris" {
  description = "Redirect URL after authentication"
  type = list(object({
    matching_mode = string
    url           = string
  }))
}

variable "signing_key_id" {
  description = "Signing Key (cert) for tokens"
  type        = string
}

variable "validity" {
  description = "Expiration/Validity for tokens"
  type = object({
    access_code   = string
    access_token  = string
    refresh_token = string
  })
  default = {
    access_code   = "minutes=1"
    access_token  = "hours=1"
    refresh_token = "hours=4"
  }
}

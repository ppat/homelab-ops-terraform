variable "bitwarden_project_id" {
  type      = string
  sensitive = true
}

variable "minio_nas_endpoint" {
  type = string
}

variable "minio_nas_user" {
  type      = string
  sensitive = true
}

variable "minio_nas_password" {
  type      = string
  sensitive = true
}

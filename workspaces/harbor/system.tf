resource "harbor_config_system" "system" {
  project_creation_restriction = "adminonly"
  robot_token_expiration       = 30
  robot_name_prefix            = "robot$"
  storage_per_project          = -1
}

resource "harbor_garbage_collection" "system" {
  schedule        = "Daily"
  delete_untagged = true
  workers         = 1
}

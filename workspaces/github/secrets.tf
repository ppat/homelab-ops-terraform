data "bitwarden_secret" "ansible_galaxy_api_token" {
  id = "ee776c16-2e8e-4dd9-afdc-b2f2016fcb25"
}

data "bitwarden_secret" "coder_ci_email" {
  id = "6b1840e1-a630-4e3a-bfb4-b2f20172b210"
}

data "bitwarden_secret" "coder_ci_password" {
  id = "23828867-1744-49a3-b290-b2f20172c64a"
}

data "bitwarden_secret" "dns_zone" {
  id = "288eeda0-d57f-4a91-8651-b2090163ecc0"
}

data "bitwarden_secret" "dockerhub_username" {
  id = "3c01b711-5aff-4787-a5cd-b2f201701236"
}

data "bitwarden_secret" "dockerhub_token" {
  id = "be4e1b76-9292-4fc4-86f5-b2f20170261e"
}

data "bitwarden_secret" "github_release_token" {
  id = "1fed8e64-1c93-4197-8164-b2f20170ba59"
}

data "bitwarden_secret" "harbor_robot_password" {
  id = "ecb70534-218a-48e8-bcd9-b2f20171469d"
}

data "bitwarden_secret" "harbor_robot_username" {
  id = "054d1e83-9b28-4df1-913d-b2f201713396"
}

data "bitwarden_secret" "homelab_bot_app_id" {
  id = "ee1b5ec1-aa5a-401c-89c8-b2550173b361"
}

data "bitwarden_secret" "homelab_bot_app_private_key" {
  id = "cc6026e0-3dc3-4846-8d6f-b20700f07a90"
}

data "bitwarden_secret" "renovate_app_id" {
  id = "221d52a5-c73d-48dd-ba4f-b2f20171ab4e"
}

data "bitwarden_secret" "renovate_app_private_key" {
  id = "04fb2359-e123-4196-a0a4-b2f20171d873"
}

data "bitwarden_secret" "tailscale_clientid" {
  id = "c54986f2-c717-42ef-996f-b22b0167a097"
}

data "bitwarden_secret" "tailscale_client_secret" {
  id = "b3d46339-8034-439e-9f90-b22d005fc6a8"
}

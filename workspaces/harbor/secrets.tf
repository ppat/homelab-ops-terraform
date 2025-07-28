data "bitwarden_secret" "dns_zone" {
  id = "288eeda0-d57f-4a91-8651-b2090163ecc0"
}

data "bitwarden_secret" "harbor_robot_password" {
  id = "ecb70534-218a-48e8-bcd9-b2f20171469d"
}

data "bitwarden_secret" "harbor_robot_username" {
  id = "054d1e83-9b28-4df1-913d-b2f201713396"
}

data "bitwarden_secret" "harbor_oidc_clientid" {
  id = "da4b5b1d-dff2-4b79-8d63-b28000aebb49"
}

data "bitwarden_secret" "harbor_oidc_clientsecret" {
  id = "e89d85ed-6218-4c4b-ace4-b28000aebac8"
}

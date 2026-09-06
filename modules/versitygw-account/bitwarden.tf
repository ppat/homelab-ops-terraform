# The key formula is versitygw-specific so these cannot collide with modules/minio-bucket's
# entries while both stores are live through the migration.
resource "bitwarden_secret" "accesskey" {
  for_each = var.accounts

  depends_on = [terraform_data.account]
  key        = "versitygw_${replace(each.key, "/[^a-zA-Z0-9]/", "")}_accesskey"
  value      = random_string.access_key[each.key].result
  project_id = var.bitwarden_project_id
  note       = "${each.key}'s versitygw access key id"
}

resource "bitwarden_secret" "secretkey" {
  for_each = var.accounts

  depends_on = [terraform_data.account]
  key        = "versitygw_${replace(each.key, "/[^a-zA-Z0-9]/", "")}_secretkey"
  value      = random_password.secret_key[each.key].result
  project_id = var.bitwarden_project_id
  note       = "${each.key}'s versitygw secret access key"
}

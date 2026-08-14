# "garage_" is hardcoded, not a variable: this module has no caller that
# isn't Garage (every resource here -- garage_key, garage_bucket_permission,
# these bitwarden_secrets -- is already Garage-only), so there's no second
# value this would ever need to be. A required variable would just be
# another call site that could drift or be typo'd; hardcoding it once makes
# collision with modules/minio-bucket's bucket_<name>_accesskey/_secretkey
# formula structurally impossible instead of dependent on every caller
# getting it right (ppat/homelab-ops-terraform#291).
#
# key_name itself is assumed unique across every module call in a given
# workspace -- callers that need one key to reach several buckets pass one
# module call with a multi-entry buckets map (see variables.tf) rather than
# several calls sharing a key_name, which is exactly what would make these
# entries collide (Bitwarden Secrets Manager's key field isn't
# enforced-unique within a project either, so a collision here wouldn't even
# fail loud).
resource "bitwarden_secret" "accesskey" {
  key        = "garage_key_${var.key_name}_accesskey"
  value      = garage_key.this.id
  project_id = var.bitwarden_project_id
  note       = "${var.key_name} Garage key's accesskey"
}

resource "bitwarden_secret" "secretkey" {
  key        = "garage_key_${var.key_name}_secretkey"
  value      = garage_key.this.secret_access_key
  project_id = var.bitwarden_project_id
  note       = "${var.key_name} Garage key's secretkey"
}

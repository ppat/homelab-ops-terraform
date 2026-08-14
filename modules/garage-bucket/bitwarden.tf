# "garage_" disambiguates from modules/minio-bucket's identical bucket_<name>_accesskey/
# _secretkey formula. Both minio-homelab and garage-homelab set bucket_prefix = "homelab"
# and share two bucket names (homelab-authentik-media, homelab-terraform-state), so an
# unprefixed key here would name-collide with MinIO's live entries. bitwarden_secret
# creates by ID, not by key name -- it never adopts an existing entry -- so a same-named
# resource here wouldn't overwrite MinIO's secret, it would either get rejected by
# Bitwarden as a duplicate key or produce two entries sharing one name that every
# ExternalSecret resolving by that name can no longer disambiguate. The 30-day
# Garage-vs-MinIO trial (apps#3611) needs both engines' credentials to exist at once under
# different names for exactly this reason; cutover is then a postBuild-variable change to
# whichever consumer's secret-store key name is parameterized (apps#3618's pattern for
# Loki), not a Bitwarden value edit in place.
#
# Hardcoded rather than a module variable: this module has no caller that isn't Garage
# (every resource here -- garage_key, garage_bucket_permission -- is already Garage-only),
# so there's no second value this would ever need to be. A required variable would just be
# a fourth call site (one per bucket-owning module block in workspaces/garage-homelab) that
# could independently drift or be typo'd; hardcoding it once here makes the collision
# structurally impossible instead of dependent on every caller remembering to set it.
resource "bitwarden_secret" "bucket_owner_accesskey" {
  key        = "bucket_garage_${replace(var.bucket_name, "/[^a-zA-Z0-9]/", "")}_accesskey"
  value      = garage_key.owner.id
  project_id = var.bitwarden_project_id
  note       = "${var.bucket_name} bucket's accesskey"
}

resource "bitwarden_secret" "bucket_owner_secretkey" {
  key        = "bucket_garage_${replace(var.bucket_name, "/[^a-zA-Z0-9]/", "")}_secretkey"
  value      = garage_key.owner.secret_access_key
  project_id = var.bitwarden_project_id
  note       = "${var.bucket_name} bucket's secretkey"
}

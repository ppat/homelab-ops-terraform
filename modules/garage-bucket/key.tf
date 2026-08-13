resource "garage_key" "owner" {
  name = var.owner_key_name
}

# read+write only, never owner: owner additionally grants control over the
# bucket itself (enable/disable website access, delete the bucket -- see
# Garage's src/model/permission.rs BucketKeyPerm), which is this module's own
# responsibility via the admin token, not something a per-service credential
# should hold. This is the Garage-native equivalent of minio-bucket's default
# owner_policy (object read/write/delete/list, no bucket administration).
resource "garage_bucket_permission" "owner" {
  bucket_id     = garage_bucket.bucket.id
  access_key_id = garage_key.owner.id
  read          = true
  write         = true
}

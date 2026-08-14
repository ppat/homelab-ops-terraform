# See variables.tf's key_name comment before ever changing this argument for
# an existing key: name carries RequiresReplace in jkossis/garage v1.0.5, so
# any change here destroys and recreates the key.
resource "garage_key" "this" {
  name = var.key_name
}

# read+write only, never owner: owner additionally grants control over the
# bucket itself (enable/disable website access, delete the bucket -- see
# Garage's src/model/permission.rs BucketKeyPerm), which is modules/garage-bucket's
# own responsibility via the admin token, not something a per-service
# credential should hold. This is the Garage-native equivalent of
# minio-bucket's default owner_policy (object read/write/delete/list, no
# bucket administration).
resource "garage_bucket_permission" "this" {
  for_each = var.buckets

  bucket_id     = each.value.bucket_id
  access_key_id = garage_key.this.id
  read          = each.value.read
  write         = each.value.write
}

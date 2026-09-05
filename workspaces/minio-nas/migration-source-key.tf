# ============================================================================
# TEMPORARY -- the read-only identity the MinIO-to-versitygw copy reads this
# store with. DELETE THIS FILE WHOLESALE (and `terraform apply`) once the copy
# and its verification are done for both buckets below. A migration credential
# that outlives its migration is standing access to the estate's only backup
# copies, held by nobody in particular.
# ============================================================================
#
# Lives at the workspace level rather than in modules/minio-bucket: it spans
# both buckets rather than belonging to either, and that module's shape is an
# owner per bucket, which is neither read-only nor shared.
#
# WHY IT EXISTS AT ALL. While the copy runs, MinIO is still the authoritative
# store -- versitygw holds no consumer's data yet. So the copier is reading the
# only copy of every backup in the estate, and the property that matters is that
# it cannot damage what it reads. The copier enforces that on its own side too,
# by refusing to expose any mutating S3 operation on its source client, but that
# is a property of its code. This is the half that holds if that code changes.
resource "minio_iam_user" "migration_source" {
  name          = "minio-versitygw-migration-source"
  force_destroy = false
}

# Read and list, nothing else. Deliberately narrower than the per-bucket owner
# policy in modules/minio-bucket, which also carries PutObject and DeleteObject.
#
# Derived from what the copier actually calls, not from a general idea of
# "read-only": list_objects_v2 (ListBucket), get_object and head_object
# (GetObject), head_bucket (HeadBucket).
#
# GetLifecycleConfiguration is WITHHELD on purpose, and its absence is load-
# bearing rather than an oversight. Reading a bucket's lifecycle rules is the
# one preflight question this credential is not meant to answer: only a key that
# can see every rule can tell "no rule is configured" apart from "I am not
# allowed to see the rule", which is why that check is run under the root
# credential instead. Denied here, the fallback path returns AccessDenied and
# the copier reports the check INCONCLUSIVE -- it never collapses that into a
# pass. Granting it would make this credential answer a question it cannot
# answer honestly.
data "minio_iam_policy_document" "migration_source" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:HeadBucket",
      "s3:ListBucket",
    ]
    resources = [
      module.cloudnativepg_backups.bucket.arn,
      "${module.cloudnativepg_backups.bucket.arn}/*",
      module.longhorn_backups.bucket.arn,
      "${module.longhorn_backups.bucket.arn}/*",
    ]
  }
}

resource "minio_iam_policy" "migration_source" {
  name   = "minio-versitygw-migration-source-policy"
  policy = data.minio_iam_policy_document.migration_source.json
}

resource "minio_iam_user_policy_attachment" "migration_source" {
  user_name   = minio_iam_user.migration_source.name
  policy_name = minio_iam_policy.migration_source.name
}

resource "minio_iam_service_account" "migration_source" {
  target_user = minio_iam_user.migration_source.name
}

# Not the bucket_<name>_* convention modules/minio-bucket writes under: that
# formula keys on a bucket, and this credential is scoped to two. Same departure
# workspaces/garage-homelab/migration-key.tf makes, for the same reason.
#
# Do not hand-create these two entries ahead of the first apply.
# `bitwarden_secret` creates a new entry by ID and never adopts an existing one
# by matching key name, so a pre-existing entry becomes a silent duplicate
# rather than an overwrite.
resource "bitwarden_secret" "migration_source_accesskey" {
  depends_on = [minio_iam_service_account.migration_source]
  key        = "minio_versitygw_migration_source_accesskey"
  value      = minio_iam_service_account.migration_source.access_key
  project_id = var.bitwarden_project_id
  note       = "MinIO->versitygw migration source key's access key id -- read+list only, on nas-cloudnativepg-backups and nas-longhorn-backups. Temporary: retire per this file's own top-of-file comment once the migration is done."
}

resource "bitwarden_secret" "migration_source_secretkey" {
  depends_on = [minio_iam_service_account.migration_source]
  key        = "minio_versitygw_migration_source_secretkey"
  value      = minio_iam_service_account.migration_source.secret_key
  project_id = var.bitwarden_project_id
  note       = "MinIO->versitygw migration source key's secret access key -- read+list only, on nas-cloudnativepg-backups and nas-longhorn-backups. Temporary: retire per this file's own top-of-file comment once the migration is done."
}

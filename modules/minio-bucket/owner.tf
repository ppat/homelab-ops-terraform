resource "minio_iam_user" "owner" {
  name          = var.owner_username
  force_destroy = false
}

data "minio_iam_policy_document" "default" {
  depends_on = [minio_s3_bucket.bucket]
  statement {
    effect = "Allow"
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:PutObject"
    ]
    resources = [
      minio_s3_bucket.bucket.arn,
      "${minio_s3_bucket.bucket.arn}/*"
    ]
  }
}

resource "minio_iam_policy" "owner_policy" {
  depends_on = [minio_s3_bucket.bucket]
  name       = "${var.bucket_name}-owner-policy"
  policy     = var.owner_policy != null ? var.owner_policy : data.minio_iam_policy_document.default.json
}

resource "minio_iam_user_policy_attachment" "owner_policy" {
  user_name   = minio_iam_user.owner.name
  policy_name = minio_iam_policy.owner_policy.name
}

resource "bitwarden_secret" "bucket_owner_accesskey" {
  depends_on = [minio_iam_user.owner]
  key        = "bucket_${replace(var.bucket_name, "/[^a-zA-Z0-9]/", "")}_accesskey"
  value      = var.owner_username
  project_id = var.bitwarden_project_id
  note       = "${var.bucket_name} bucket's accesskey"
}

resource "bitwarden_secret" "bucket_owner_secretkey" {
  depends_on = [minio_iam_user.owner]
  key        = "bucket_${replace(var.bucket_name, "/[^a-zA-Z0-9]/", "")}_secretkey"
  value      = minio_iam_user.owner.secret
  project_id = var.bitwarden_project_id
  note       = "${var.bucket_name} bucket's secretkey"
}

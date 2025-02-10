locals {
  authentik_media_bucket     = "${local.bucket_prefix}-authentik-media"
  authentik_media_bucket_arn = "arn:aws:s3:::${local.authentik_media_bucket}"
}

module "authentik_media" {
  source = "../../modules/minio-bucket"

  bucket_name          = local.authentik_media_bucket
  bucket_policy        = data.minio_iam_policy_document.authentik_public_access.json
  owner_username       = "authentik"
  bitwarden_project_id = var.bitwarden_project_id
}

data "minio_iam_policy_document" "authentik_public_access" {
  statement {
    effect    = "Allow"
    principal = "*"
    actions   = ["s3:GetBucketLocation", "s3:ListBucket"]
    resources = [local.authentik_media_bucket_arn]
  }
  statement {
    effect    = "Allow"
    principal = "*"
    actions   = ["s3:GetObject"]
    resources = ["${local.authentik_media_bucket_arn}/*"]
  }
}

module "terraform_state" {
  source = "../../modules/minio-bucket"

  bucket_name          = "${local.bucket_prefix}-terraform-state"
  owner_username       = "terraform"
  bitwarden_project_id = var.bitwarden_project_id
}

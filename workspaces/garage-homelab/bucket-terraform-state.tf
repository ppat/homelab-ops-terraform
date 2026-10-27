# This bucket hosts this repo's own Terraform state for every workspace,
# including this one -- the first apply that created it could not itself be
# backed by it (a backend can't bootstrap into a bucket the same run
# creates). See terraform.tf for the DR consequence of that.
module "terraform_state" {
  source = "../../modules/garage-bucket"

  bucket_name           = "${local.bucket_prefix}-terraform-state"
  garage_admin_endpoint = var.garage_admin_endpoint
  garage_admin_token    = var.garage_admin_token
}

module "terraform_state_key" {
  source = "../../modules/garage-key"

  key_name = "terraform"
  buckets = {
    terraform_state = {
      bucket_id = module.terraform_state.bucket.id
      read      = true
      write     = true
    }
  }
  bitwarden_project_id = var.bitwarden_project_id
}

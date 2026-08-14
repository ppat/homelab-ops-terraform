# This bucket is meant to eventually host this repo's OWN Terraform state (see
# terraform.tf: every workspace's backend, including this one, still points at
# the existing MinIO-hosted homelab-terraform-state bucket for now) -- creating
# it here does not migrate anything. That migration is a deliberate, separate
# cutover: each workspace's backend block would need to move to this bucket
# after it exists, and the very first apply that creates it can't itself be
# backed by it (a state backend can't bootstrap into a bucket the same run is
# what creates). Disaster recovery is the same story in reverse: recovering
# this Garage instance from scratch requires getting Terraform state back by
# some other means before this bucket -- and therefore every other workspace's
# backend -- can be reached again. Pre-existing risk inherited from the MinIO
# original, not introduced here; flagging for whoever does the cutover.
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

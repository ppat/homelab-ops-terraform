# Adding a consumer is one entry here; nothing presumes how many there are.
#
# Three operating rules, each about an action taken from this file rather than from the
# module:
#
#  1. REMOVING AN ENTRY deletes that account in the gateway and leaves its bucket and every
#     object in it untouched -- the bucket resource has no destroy-time action at all.
#     Deleting a credential is reversible; deleting a bucket is not.
#  2. DELETING THIS `module` BLOCK is not the same thing. Terraform destroys from state
#     alone, so a destroy-time provisioner that has left the configuration never runs: every
#     account below stays live in the gateway, including the admin one, while the Bitwarden
#     entries recording their keys are destroyed in the same apply -- after which nothing
#     outside the gateway knows what the live credentials are. Run `terraform destroy` here
#     first, then remove the block. This matters at a known future moment: this workspace is
#     meant to be decommissioned once the store it provisions is retired.
#  3. ROTATING A CREDENTIAL means tainting `random_password.secret_key["<name>"]` and
#     nothing else. Tainting `random_string.access_key["<name>"]` additionally re-homes that
#     account's bucket, which discards the bucket's ACL and policy and opens a window in
#     which the ACL names a deleted access key and only an admin credential can read the
#     data. Both resources are in modules/versitygw-account/account.tf, where the mechanism
#     is spelled out.
module "accounts" {
  source = "../../modules/versitygw-account"

  accounts = {
    cloudnativepg = { bucket = "${local.bucket_prefix}-cloudnativepg-backups" }
    longhorn      = { bucket = "${local.bucket_prefix}-longhorn-backups" }

    # Owns no bucket. What it buys is revocability, not distance from root: the admin gate
    # is role-only with no root check, and root is itself synthesised as an admin-role
    # account at authentication time, so this credential is functionally equivalent to root
    # -- it can delete any bucket, and list-users returns every account's secret key in
    # cleartext. The gain is that retiring it is one entry removed from this map, whereas
    # root is a startup credential whose rotation restarts the gateway.
    webui-admin = { role = "admin" }

    # TEMPORARY -- the identity the MinIO-to-versitygw copy writes with, so that workload
    # neither borrows a consumer's key nor holds the gateway's startup credential. DELETE
    # THIS ENTRY (and apply) once the copy and its verification are done. Removing it
    # deletes the account and cannot touch either bucket: the bucket resource has no
    # destroy-time action, which is the same structural asymmetry rule 1 above describes.
    #
    # role = admin is what "can write both consumers' buckets" costs here, and it is not a
    # scoping choice: versitygw's roles are exactly user, userplus and admin, only admin
    # bypasses the per-bucket ACL, and no admin endpoint grants a non-owner any access to a
    # bucket. So this credential can reach every bucket in the store and read every
    # account's secret in cleartext, exactly like webui-admin -- while it exists, the store
    # has three store-wide credentials rather than one. Its whole value is that it is the
    # one of the three that is meant to stop existing, on a schedule, by deleting a line.
    #
    # It does not replace the per-consumer check: the copy's preflight is also run once per
    # consumer under that consumer's own key, which is what proves the credential path the
    # consumer uses after cutover can write its own bucket. Different claim, different
    # credential (ppat/homelab-ops-kubernetes-clusters#1028).
    migration = { role = "admin" }
  }

  bitwarden_project_id = var.bitwarden_project_id
}

module "cloudnativepg_backups" {
  source = "../../modules/minio-bucket"

  bucket_name = "${local.bucket_prefix}-cloudnativepg-backups"

  # 31 is correct here, but not for the same reason as the longhorn-backups bucket (see its
  # comment) -- don't "harmonise" the two to a shared number for tidiness. Barman base
  # backups are self-contained with no cross-backup block sharing, so there's no
  # content-addressing hazard and the floor is simply:
  #   object_expiration_days >= retentionPolicy + base_backup_interval
  # This estate: retentionPolicy "30d" + an 8-hourly ScheduledBackup (0 0 4,12,20 * * *)
  # gives a floor of 30d 8h, which 31d clears by ~16h. Verified live:
  # firstRecoverabilityPoint on the coder DB's backup store measured 30d 7h50m, matching
  # the predicted bound. This margin is thin and one-directional: if the ScheduledBackup
  # interval is ever lengthened, it goes negative.
  object_expiration_days = 31

  owner_username       = "cloudnativepg"
  bitwarden_project_id = var.bitwarden_project_id
}

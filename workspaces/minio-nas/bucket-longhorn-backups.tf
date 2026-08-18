module "longhorn_backups" {
  source = "../../modules/minio-bucket"

  bucket_name = "${local.bucket_prefix}-longhorn-backups"

  # No object_expiration_days: Longhorn's own documentation for 1.11.x prohibits
  # backupstore-side lifecycle/retention rules entirely -- backupstore lifecycle is
  # managed exclusively by Longhorn -- so this bucket must not have one, not "a carefully
  # sized one". A prior age-based rule (31d) was removed rather than raised.
  #
  # Why removing it loses no reclamation: Longhorn already reaps its own backups.
  # DeleteDeltaBlockBackup runs a per-volume mark-and-sweep on every backup deletion --
  # which the recurring job's `retain: 30` triggers nightly -- refcounting every block
  # against the backups that remain and deleting the zero-refcount ones. An age-based
  # bucket rule adds no reclamation Longhorn wasn't already doing.
  #
  # Why the rule was actively harmful: Longhorn's backupstore is content-addressed --
  # unchanged blocks aren't re-uploaded on incremental backups, so a still-referenced
  # block's object age is the age of its LAST upload, not of the backup that references
  # it. Only a full backup (reUpload=true) rewrites a block under its content-addressed
  # key and resets that age. An age-based rule can only be non-destructive if it clears:
  #   object_expiration_days >= retention_window + full_backup_cadence
  # Measured on this estate: retention_window = 30d (recurring job `retain: 30`, confirmed
  # by 30 Backup CRs spanning 2026-07-20..2026-08-18); full_backup_cadence = 7d
  # (`full-backup-interval: 7` fires every 7th job *execution*, not every 7 days --
  # longhorn-manager v1.11.2 recurringjob/volume.go: executionCount % interval == 0 --
  # which is 7 days on this daily job; confirmed by reUploadedDataSize jumping to 236.8MB
  # on 2026-08-07 and 230.1MB on 2026-08-14, vs. 0 on every sampled incremental between).
  # Floor = 37d against the 31d configured: a 6-day window in which retained backups could
  # reference blocks the rule had already deleted. No value below the floor is safe, and
  # per Longhorn's own docs no value at all is the correct answer -- don't reach for a
  # "safer" number here.
  #
  # Live evidence the removed rule was reaching live data: longhorn-manager logged, every
  # 30s, "Failed to list backups from backup target: cannot find
  # backupstore/volumes/.../volume.cfg in backupstore" for three distinct volumes. All
  # three have since been deleted, so no live volume's backup is known damaged.

  owner_username       = "longhorn"
  bitwarden_project_id = var.bitwarden_project_id
}

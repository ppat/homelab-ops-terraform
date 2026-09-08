# The bucket names are the ones MinIO serves today, so each consumer's cutover moves its
# endpoint and credentials and nothing else.
locals {
  bucket_prefix = "nas"
}

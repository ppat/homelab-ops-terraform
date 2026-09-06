# No destroy-time provisioner, so removing a consumer leaves its bucket and objects alone.
# State and the store therefore diverge by design, and a re-added consumer is planned as a
# create against a bucket that still exists -- which is why the script converges rather
# than creates.
resource "terraform_data" "bucket" {
  for_each = { for name, account in var.accounts : name => account if account.bucket != null }

  depends_on = [terraform_data.account]

  input = each.value.bucket

  triggers_replace = {
    bucket = each.value.bucket
    owner  = random_string.access_key[each.key].result
  }

  # One call creates the bucket and assigns its owner, so it is never present unowned.
  provisioner "local-exec" {
    command = "python3 ${path.module}/scripts/versitygw-admin.py converge-bucket"
    environment = {
      VERSITYGW_BUCKET       = each.value.bucket
      VERSITYGW_BUCKET_OWNER = random_string.access_key[each.key].result
    }
  }
}

output "accounts" {
  description = "Per account: its generated access key id, the bucket it owns, and where its credentials were written."
  value = {
    for name, account in var.accounts : name => {
      access_key = random_string.access_key[name].result
      bucket     = account.bucket
      bitwarden = {
        accesskey = bitwarden_secret.accesskey[name].key
        secretkey = bitwarden_secret.secretkey[name].key
      }
    }
  }
}

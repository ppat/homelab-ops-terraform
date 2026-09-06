# Keyed instances, not one module call per consumer: removing a whole `module` block takes
# these provisioners out of configuration along with the resources, so the destroy-time
# delete never runs and every account stays live in the gateway. Run `terraform destroy`
# before removing this module from a workspace.
resource "random_string" "access_key" {
  for_each = var.accounts

  length  = 20
  upper   = true
  lower   = false
  numeric = true
  special = false
}

# Alphanumeric only: these travel through consumer config files and URLs, where `/` and `+`
# are an escaping hazard.
resource "random_password" "secret_key" {
  for_each = var.accounts

  length      = 40
  special     = false
  min_upper   = 1
  min_lower   = 1
  min_numeric = 1
}

resource "terraform_data" "account" {
  for_each = var.accounts

  # Carries the access key and nothing secret, because `input` is written to state. The
  # admin credential reaches the script through the environment instead.
  input = random_string.access_key[each.key].result

  triggers_replace = {
    access = random_string.access_key[each.key].result
    role   = each.value.role
    secret = random_password.secret_key[each.key].result
  }

  # Values go in `environment`, never interpolated into `command`: the command string is
  # evaluated by /bin/sh before the script runs, so a bucket name containing `;` executes.
  provisioner "local-exec" {
    command = "python3 ${path.module}/scripts/versitygw-admin.py converge-account"
    environment = {
      VERSITYGW_ACCOUNT_ACCESS = random_string.access_key[each.key].result
      VERSITYGW_ACCOUNT_SECRET = random_password.secret_key[each.key].result
      VERSITYGW_ACCOUNT_ROLE   = each.value.role
    }
  }

  # Removing an entry deletes the account; the bucket beside it has no destroy provisioner,
  # so its data survives. Deleting a credential is reversible and deleting a bucket is not.
  provisioner "local-exec" {
    when        = destroy
    command     = "python3 ${path.module}/scripts/versitygw-admin.py delete-account"
    environment = { VERSITYGW_ACCOUNT_ACCESS = self.input }
  }
}

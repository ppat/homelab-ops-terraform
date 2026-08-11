# Write-back only, deliberately decoupled from object-permission.tf: the plaintext token
# is available the moment litellm_key.this is created, regardless of whether the
# object_permission REST seam has run or succeeded, so this depends only on the
# resource that actually produces the credential — never on the seam.
resource "bitwarden_secret" "apikey" {
  depends_on = [litellm_key.this]
  key        = "apikey_litellm_${replace(var.consumer, "/[^a-zA-Z0-9]/", "")}"
  value      = litellm_key.this.key
  project_id = var.bitwarden_project_id
  note       = "LiteLLM virtual key (sk-...) for ${var.consumer}"
}

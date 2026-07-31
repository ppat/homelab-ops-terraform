module "repo_obsidian_vault" {
  source = "../../modules/github-repository"
  repository = {
    name        = "obsidian-vault"
    description = ""
    visibility  = "private"
  }
}

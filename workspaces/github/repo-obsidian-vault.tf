module "repo_obsidian_vault" {
  source = "../../modules/github-repository"
  repository = {
    name        = "obsidian-vault"
    description = ""
    visibility  = "private"
  }
  # The only writer is a machine: the vault's git committer, pushing derived history on a schedule
  # with a deploy key scoped to this repository alone (ppat/obsidian-tools#3). Requiring verified
  # signatures here would block it -- and buy nothing, because the signature would be made with the
  # same key an attacker would have to steal to push in the first place. That is provenance display,
  # not a second factor.
  #
  # Making it genuinely "Verified" would also cost more than it looks: GitHub only verifies an SSH
  # signature when the signing key belongs to an account AND the commit email is a verified address
  # on that account, so the committer would have to author as a human. The vault's whole provenance
  # model rests on telling machine writes from human ones, so that trade is backwards here.
  #
  # Revisit if this repository ever gains a second writer, or if the committer is given a signing
  # key distinct from its auth key -- at that point signing would mean something.
  require_signed_commits = false
}

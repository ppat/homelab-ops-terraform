# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Terraform configuration for a home-lab: workspaces provisioning Authentik, GitHub,
Harbor, and MinIO (two independent instances). Workspaces manage a mix of resources
running on local homelab infrastructure (Authentik, Harbor, MinIO) and on external/cloud
services (GitHub; more may follow, e.g. Cloudflare, Hetzner) — don't assume a workspace is
purely local or purely cloud without checking its provider config.

## Before making changes

- Check the relevant root-level linter/formatter config before editing a file of that
  type — `.tflint.hcl` and `.checkov.yaml` for Terraform, `.yamllint` for YAML,
  `.markdownlint-cli2.yaml` for Markdown, `.pre-commit-config.yaml` for the full hook set,
  `commitlint.config.js` for commit message rules, `trivy.yaml`/`.trivyignore.yaml` for
  scan scope. Don't guess at conventions — these files are the source of truth.
- Adding a new module or workspace directory requires adding its name to the
  `scope-enum` list in `commitlint.config.js` (see Commit conventions below), or commits
  scoped to it will fail linting.

## Repository layout

- `workspaces/<name>/` — root Terraform configurations, each an independent state/backend.
  Currently: `authentik`, `github`, `harbor`, `minio-homelab`, `minio-nas`. There is also a
  `workspaces/cloudflare/` and `modules/cloudflare-tunnel/` placeholder directory (no
  tracked `.tf` files yet) — not a real workspace/module until content is added.
- `modules/<name>/` — reusable modules consumed by workspaces via relative `source` paths
  (e.g. `../../modules/minio-bucket`).

Each workspace/module directory is self-contained Terraform: `terraform.tf` (backend +
provider requirements), `variables.tf`, `main.tf`/resource-specific `*.tf` files,
`outputs.tf` where relevant.

### Workspaces vs. modules — key differences

- **Version pinning**: workspaces pin exact provider versions (e.g. `version = "3.38.3"`);
  modules use loose lower-bound constraints (e.g. `version = ">= 3.2"`). Follow this pattern
  when bumping or adding providers.
- **Lock files**: only workspace `.terraform.lock.hcl` files are committed to git; module
  lock files are gitignored (see the comment in `.gitignore`). Don't add a module's lock file
  to a commit.
- **Backend**: every workspace uses the same S3-compatible backend pointed at a MinIO bucket
  (`homelab-terraform-state`), keyed as `<workspace-name>/terraform.tfstate`, with
  `skip_credentials_validation`/`skip_requesting_account_id`/`skip_metadata_api_check`/
  `skip_region_validation`/`force_path_style` all `true`. Modules never define a backend.

### Secrets pattern (Bitwarden Secrets Manager)

Every workspace and most modules declare the `bitwarden` provider
(`maxlaverse/bitwarden`, `experimental { embedded_client = true }`). Two directions:

- **Reading**: workspaces reference existing secrets by hardcoded UUID via
  `data "bitwarden_secret" "..."  { id = "..." }` (see `workspaces/authentik/secrets.tf`,
  `workspaces/github/secrets.tf`).
- **Writing**: modules that provision credentials write them back with
  `resource "bitwarden_secret" "..."` into a caller-supplied `bitwarden_project_id`
  (see `modules/minio-bucket/owner.tf`).

Each workspace has a `.ci.env` file with dummy placeholder values (`BWS_ACCESS_TOKEN`,
provider endpoint vars) — these mark the env vars a CI/local run needs, not real secrets.

## Commands

Tool versions are pinned in `mise.toml` (terraform 1.6.6, tflint, checkov, terraform-docs,
node/bun for commit linting, uv). Run `mise install` once to get matching toolchain versions.

Run all Terraform commands from inside the specific workspace or module directory
(e.g. `workspaces/minio-nas/`, `modules/minio-bucket/`) — there is no root-level
`terraform` invocation.

Before running `terraform init` or `terraform validate` in a **workspace**, source that
workspace's `.ci.env` (e.g. `workspaces/minio-nas/.ci.env`) to populate the env vars its
providers expect (`BWS_ACCESS_TOKEN`, endpoint/credential vars, etc.) — real values for
local work, the file's placeholder values are only enough to satisfy `terraform validate`.
Modules don't have a `.ci.env` since they declare no provider config of their own.

```bash
# init/validate/plan a single workspace or module
cd workspaces/<name>  # or modules/<name>
set -a && source .ci.env && set +a   # workspaces only
terraform init
terraform fmt -check -recursive   # from repo root to check all dirs at once
terraform validate
terraform plan

# lint a single terraform dir (mirrors CI)
tflint --config="$(git rev-parse --show-toplevel)/.tflint.hcl"

# security/config scan (mirrors CI's checkov-scan job)
checkov --config-file .checkov.yaml -d .

# vulnerability/misconfig/secret scan (mirrors CI's trivy-scan job)
trivy fs --config trivy.yaml .

# run all pre-commit hooks (fmt, validate, tflint, checkov, yamllint, shellcheck, gitleaks, commitlint)
pre-commit run --all-files
```

There is no test suite; correctness is enforced via `terraform validate`, `tflint`,
`checkov`, `trivy`, and `pre-commit`, all wired into CI (see below).

## CI (`.github/workflows/`)

All jobs delegate to reusable workflows in `ppat/github-workflows` (pinned by SHA) —
this repo's `.yaml` files are thin callers, not the actual logic.

- `lint.yaml` — runs on every PR; a `detect-changes` job scopes each linter (terraform,
  yaml, markdown, shellcheck, github-actions, zizmor, renovate-config, commit messages,
  pre-commit) to only the relevant changed files. The `terraform-dirs` job has custom logic:
  if any file under `modules/` changed, it validates *all* workspaces plus the changed
  modules (since a module change can affect every consumer); otherwise it validates only
  the changed workspaces.
- `scan-pr.yaml` / `scan-scheduled.yaml` — Trivy + Checkov scans; scheduled run also
  uploads SARIF to the GitHub Security tab.
- `renovate.yaml` — self-hosted Renovate, dry-run on PRs touching its own config, real run
  nightly.

## Commit conventions

Conventional Commits, enforced by commitlint (`commitlint.config.js`) via a pre-commit hook.
`scope-enum` restricts the scope to a fixed list of module/workspace names plus
`dev-tools`, `github-actions`, `release`, `renovate`, `terraform-provider`,
`terraform-version`. Every module and workspace directory must have a matching entry in
this list — when adding a new one, add its name to `scope-enum` in the same change,
otherwise commits scoped to it will fail commitlint.

## Renovate

`.github/renovate.json` extends shared presets from `ppat/renovate-presets` and applies
repo-local rules from `.github/renovate/`:

- `template-terraform-provider.json` — groups/paces terraform-provider updates under
  `workspaces/**` by update type (patch auto-merges after 1 day, minor after 30 days,
  major after 90 days).
- `exceptions.json` — pins `terraform`/`hashicorp/terraform` to `<=1.6.6` for OpenTofu
  compatibility.

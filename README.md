# homelab-ops-terraform

Terraform configuration for a home lab, provisioning Authentik, GitHub, Harbor, and two
independent MinIO instances. Resources span both local homelab infrastructure (Authentik,
Harbor, MinIO) and external/cloud services (GitHub).

## Layout

All state is stored remotely in an S3-compatible backend (a MinIO bucket). Secrets are
read from and written to Bitwarden Secrets Manager via the `bitwarden` provider.

### Workspaces

Root Terraform configurations under `workspaces/<name>/`, each an independent
state/backend.

| Name | Description |
|------|-------------|
| [`authentik`](workspaces/authentik) | Authentik SSO — applications, providers, and outposts |
| [`github`](workspaces/github) | GitHub org repository configuration |
| [`harbor`](workspaces/harbor) | Harbor container registry — auth, system config, robot accounts |
| [`minio-homelab`](workspaces/minio-homelab) | MinIO instance on homelab infra — Terraform state and Authentik media buckets |
| [`minio-nas`](workspaces/minio-nas) | MinIO instance on NAS — CloudNativePG and Longhorn backup buckets |

### Modules

Reusable modules under `modules/<name>/`, consumed by workspaces via relative `source`
paths.

| Name | Description |
|------|-------------|
| [`authentik-oauth2-application`](modules/authentik-oauth2-application) | Authentik OAuth2 provider + application + group binding |
| [`authentik-proxy-application`](modules/authentik-proxy-application) | Authentik proxy provider + application + group binding |
| [`github-repository`](modules/github-repository) | GitHub repository, branch protection, actions, environments |
| [`harbor-local-registry`](modules/harbor-local-registry) | Harbor local (push) registry with retention policy |
| [`harbor-proxy-registry`](modules/harbor-proxy-registry) | Harbor pull-through proxy registry with retention policy |
| [`minio-bucket`](modules/minio-bucket) | MinIO bucket with lifecycle rules and owner credentials |

## Prerequisites

Tool versions are pinned in `mise.toml` (Terraform, tflint, checkov, terraform-docs,
node/bun, uv):

```bash
mise install
```

## Usage

Run all Terraform commands from inside the specific workspace or module directory —
there is no root-level `terraform` invocation:

```bash
cd workspaces/<name>  # or modules/<name>

# workspaces only: populate provider env vars (BWS_ACCESS_TOKEN, endpoint/credential vars)
set -a && source .ci.env && set +a

terraform init
terraform validate
terraform plan
```

### Linting and scanning

```bash
terraform fmt -check -recursive               # from repo root, checks all dirs
tflint --config="$(git rev-parse --show-toplevel)/.tflint.hcl"
checkov --config-file .checkov.yaml -d .
trivy fs --config trivy.yaml .
pre-commit run --all-files                    # runs the full hook set
```

There is no test suite; correctness is enforced via `terraform validate`, `tflint`,
`checkov`, `trivy`, and `pre-commit`, all wired into CI.

## Commit conventions

Conventional Commits, enforced by commitlint (`commitlint.config.js`). Commit scopes are
restricted to a fixed list of module/workspace names — see `scope-enum` in that file.

## License

[GNU AGPLv3](LICENSE)

# Remote/SaaS MCP servers ONLY. Self-hosted MCP servers stay file-declared in the apps repo's
# LiteLLM HelmRelease and are not represented here. There are zero Terraform-managed remote/SaaS
# MCP servers today. When one is needed, add a concrete instance here — NOT a map variable —
# following the instance pattern in workspaces/minio-nas/bucket-*.tf:
#
# module "some_server_name" {
#   source = "../../modules/litellm-mcp-server"
#
#   server_name = "some_server_name"
#   url         = "https://..."
#
#   existing_mcp_servers = data.litellm_mcp_servers.all.mcp_servers
# }
#
# One module block per server, real config committed inline — see main.tf for the shared
# data.litellm_mcp_servers.all this and every future instance's collision guard reads from.

# GitHub MCP on Smithery
Remote-hosted GitHub MCP server via mcp-proxy (Streamable HTTP/SSE).

## Required env
- GITHUB_PERSONAL_ACCESS_TOKEN (PAT with least-privilege)
- Optional:
  - GITHUB_TOOLSETS="repos,issues,pull_requests,actions,code_security"  # or "all"
  - GITHUB_READ_ONLY=1                                                  # safe default
  - GITHUB_DYNAMIC_TOOLSETS=1
  - GITHUB_HOST="https://<your-ghes-or-ghe.com>"                        # if Enterprise

## Port
- Exposes Streamable HTTP/SSE on :8080

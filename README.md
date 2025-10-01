# GitHub MCP Server on Smithery

This repo containerizes [github-mcp-server](https://github.com/github/github-mcp-server) 
and exposes it via [mcp-proxy](https://pypi.org/project/mcp-proxy/) as a remote 
Streamable HTTP/SSE server.

## Deployment

Deployed automatically on [Smithery](https://smithery.ai) from this repo.

## Environment Variables
- `GITHUB_PERSONAL_ACCESS_TOKEN` (required)  
  - PAT from GitHub with minimal scopes:
    - `public_repo` (for public repos only)
    - Add `repo` (for private repos)
    - Add `read:org` (if querying org info)
- `GITHUB_READ_ONLY=1` (optional, safe default)
- `GITHUB_TOOLSETS="repos,issues,pull_requests,actions,code_security"` (optional)
- `GITHUB_DYNAMIC_TOOLSETS=1` (optional)
- `GITHUB_HOST="https://<your-ghes>"` (optional, for GH Enterprise)

## Port
Exposes Streamable HTTP/SSE on port `8080`.

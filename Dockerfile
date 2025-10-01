# --- build the GitHub MCP server (Go) ---
FROM golang:1.24 AS build
WORKDIR /src

# Copy local workspace if present (small context). If there's no go.mod, clone upstream.
COPY . /src

RUN if [ -f go.mod ]; then \
      echo "Using local workspace"; \
      go env -w GO111MODULE=on && go mod download; \
    else \
      echo "No go.mod found in context — cloning upstream repo"; \
      git clone --depth 1 https://github.com/github/github-mcp-server .; \
      go env -w GO111MODULE=on && go mod download; \
    fi \
 && CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /out/github-mcp-server ./cmd/github-mcp-server

# --- minimal runtime with mcp-proxy exposing Streamable HTTP/SSE ---
FROM python:3.12-slim
WORKDIR /app
RUN pip install --no-cache-dir mcp-proxy
COPY --from=build /out/github-mcp-server /usr/local/bin/github-mcp-server
RUN chmod +x /usr/local/bin/github-mcp-server

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080', timeout=2).read()"

ENTRYPOINT ["mcp-proxy","--host","0.0.0.0","--port","8080","--","/usr/local/bin/github-mcp-server","stdio"]

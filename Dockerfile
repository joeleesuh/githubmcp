# --- build the GitHub MCP server (Go) ---
FROM golang:1.24 AS build
WORKDIR /src

# Clone upstream first into an initially-empty directory so git never tries to write into an already-populated path.
# Then copy local workspace on top to allow local overrides (if present).
RUN git clone --depth 1 https://github.com/github/github-mcp-server /src || true

# Copy local workspace to overwrite upstream files when present.
COPY . /src

# If go.mod exists (either local or from upstream), download modules and build.
RUN if [ -f go.mod ]; then \
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

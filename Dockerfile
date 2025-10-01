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
COPY --from=build /out/github-mcp-server /usr/local/bin/github-mcp-server-bin

# wrapper reads token file and execs real binary
COPY github-mcp-server-wrapper /usr/local/bin/github-mcp-server-wrapper
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/github-mcp-server-bin /usr/local/bin/github-mcp-server-wrapper /usr/local/bin/docker-entrypoint.sh \
 && ln -sf /usr/local/bin/github-mcp-server-wrapper /usr/local/bin/github-mcp-server

# keep healthcheck etc.
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080', timeout=2).read()"

# start entrypoint which creates token file then launches mcp-proxy
ENTRYPOINT ["sh","/usr/local/bin/docker-entrypoint.sh"]

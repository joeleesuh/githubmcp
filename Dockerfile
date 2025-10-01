# --- build the GitHub MCP server (Go) ---
FROM golang:1.24 AS build
WORKDIR /src

# Copy module files first so Docker cache can reuse downloads.
COPY go.mod go.sum ./

RUN go env -w GO111MODULE=on \
 && go mod download

# Now copy the rest of the source
COPY . .

# Ensure modules, produce a static linux binary
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /out/github-mcp-server ./cmd/github-mcp-server

# --- minimal runtime with mcp-proxy exposing Streamable HTTP/SSE ---
FROM python:3.12-slim
WORKDIR /app
# Install proxy that converts stdio <-> Streamable HTTP/SSE
RUN pip install --no-cache-dir mcp-proxy
# Add server binary
COPY --from=build /out/github-mcp-server /usr/local/bin/github-mcp-server
RUN chmod +x /usr/local/bin/github-mcp-server

# Health + basics
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s --retries=3 CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8080', timeout=2).read()"

# Start proxy on 0.0.0.0:8080 and spawn stdio server behind it
# Pass through env for the server (token, toolsets, etc.)
ENTRYPOINT ["mcp-proxy","--host","0.0.0.0","--port","8080","--","/usr/local/bin/github-mcp-server","stdio"]

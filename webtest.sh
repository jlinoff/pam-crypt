#!/usr/bin/env bash
set -euo pipefail

PORT="${PORT:-9001}"
URL="http://127.0.0.1:${PORT}/pam-vault-diff.html"

python3 - "$PORT" <<'PY' &
import http.server
import socketserver
import sys

port = int(sys.argv[1])

with socketserver.TCPServer(("127.0.0.1", port),
                            http.server.SimpleHTTPRequestHandler) as server:
    server.handle_request()
PY

HTTP_SERVER_PID=$!

trap 'kill "$HTTP_SERVER_PID" 2>/dev/null || true' EXIT INT TERM

open "$URL"
wait "$HTTP_SERVER_PID"

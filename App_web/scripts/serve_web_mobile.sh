#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/tikiya_web"

WEB_HOST="${WEB_HOST:-0.0.0.0}"
WEB_PORT="${WEB_PORT:-3000}"
WEB_PORT_STRICT="${WEB_PORT_STRICT:-0}"

is_port_in_use() {
  local port="$1"
  if command -v ss >/dev/null 2>&1; then
    ss -ltnH "sport = :$port" 2>/dev/null | grep -q .
    return $?
  fi

  if command -v lsof >/dev/null 2>&1; then
    lsof -nP -iTCP:"$port" -sTCP:LISTEN >/dev/null 2>&1
    return $?
  fi

  python3 - <<PY >/dev/null 2>&1
import socket
s = socket.socket()
try:
    s.bind(('0.0.0.0', int('$port')))
except OSError:
    raise SystemExit(0)
else:
    raise SystemExit(1)
finally:
    s.close()
PY
}

choose_free_port() {
  local start_port="$1"
  local port="$start_port"
  while [[ "$port" -le 3100 ]]; do
    if ! is_port_in_use "$port"; then
      echo "$port"
      return 0
    fi
    port=$((port + 1))
  done
  return 1
}

if ! command -v flutter >/dev/null 2>&1; then
  echo "flutter not found in PATH" >&2
  exit 127
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 not found in PATH" >&2
  exit 127
fi

cd "$APP_DIR"

flutter pub get

BUILD_ARGS=(web)
if [[ "${WASM:-0}" == "1" ]]; then
  BUILD_ARGS+=(--wasm)
fi

flutter build "${BUILD_ARGS[@]}"

if is_port_in_use "$WEB_PORT"; then
  if [[ "$WEB_PORT_STRICT" == "1" ]]; then
    echo "Port $WEB_PORT is already in use. Choose another port (or unset WEB_PORT), e.g.: WEB_PORT=3001 ./scripts/serve_web_mobile.sh" >&2
    exit 1
  fi

  new_port="$(choose_free_port "$WEB_PORT" || true)"
  if [[ -z "$new_port" ]]; then
    echo "No free port found starting at $WEB_PORT (up to 3100)." >&2
    exit 1
  fi
  WEB_PORT="$new_port"
fi

echo
printf 'Serving build/web on http://%s:%s/\n' "$WEB_HOST" "$WEB_PORT"
python3 - "$WEB_HOST" "$WEB_PORT" <<'PY'
import os
import posixpath
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import unquote, urlsplit
import sys

HOST = sys.argv[1]
PORT = int(sys.argv[2])
DIRECTORY = os.path.join(os.getcwd(), 'build', 'web')


class SpaHandler(SimpleHTTPRequestHandler):
  def do_GET(self):
    path = urlsplit(self.path).path
    if path == '/favicon.ico' and os.path.exists(os.path.join(DIRECTORY, 'favicon.png')):
      self.path = '/favicon.png'
      return super().do_GET()

    clean_path = posixpath.normpath(unquote(path))
    full_path = os.path.join(DIRECTORY, clean_path.lstrip('/'))
    has_extension = os.path.splitext(clean_path)[1] != ''

    if clean_path not in ('', '/') and (not has_extension) and (not os.path.exists(full_path)):
      self.path = '/index.html'

    return super().do_GET()


handler = partial(SpaHandler, directory=DIRECTORY)
with ThreadingHTTPServer((HOST, PORT), handler) as httpd:
  print(f'SPA server ready on http://{HOST}:{PORT}/ (root: {DIRECTORY})')
  httpd.serve_forever()
PY

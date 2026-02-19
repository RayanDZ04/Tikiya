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
python3 -m http.server "$WEB_PORT" --bind "$WEB_HOST" --directory build/web

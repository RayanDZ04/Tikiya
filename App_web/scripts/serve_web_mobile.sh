#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/tikiya_web"

WEB_HOST="${WEB_HOST:-0.0.0.0}"
WEB_PORT="${WEB_PORT:-3000}"

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

echo
printf 'Serving build/web on http://%s:%s/\n' "$WEB_HOST" "$WEB_PORT"
python3 -m http.server "$WEB_PORT" --bind "$WEB_HOST" --directory build/web

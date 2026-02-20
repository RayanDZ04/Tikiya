#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/tikiya_web"

WEB_HOST="${WEB_HOST:-0.0.0.0}"
WEB_PORT="${WEB_PORT:-3000}"
WEB_PORT_STRICT="${WEB_PORT_STRICT:-0}"

# SMTP settings for form emails
SMTP_HOST="${SMTP_HOST:-}"
SMTP_PORT="${SMTP_PORT:-587}"
SMTP_USERNAME="${SMTP_USERNAME:-}"
SMTP_PASSWORD="${SMTP_PASSWORD:-}"
SMTP_FROM="${SMTP_FROM:-noreply@tikiya.dz}"
ORGANIZER_NEEDS_TO_EMAIL="${ORGANIZER_NEEDS_TO_EMAIL:-rayanbenhabiles9@gmail.com}"
SMTP_TLS="${SMTP_TLS:-1}"

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

if is_port_in_use "$WEB_PORT"; then
    if [[ "$WEB_PORT_STRICT" == "1" ]]; then
        echo "Port $WEB_PORT is already in use. Choose another port with WEB_PORT=XXXX." >&2
        exit 1
    fi

    new_port="$(choose_free_port "$WEB_PORT" || true)"
    if [[ -z "$new_port" ]]; then
        echo "No free port found starting at $WEB_PORT (up to 3100)." >&2
        exit 1
    fi
    WEB_PORT="$new_port"
fi

cd "$APP_DIR"
flutter pub get
flutter build web --dart-define=API_BASE_URL=/api

echo
printf 'Phase 1 server on http://%s:%s/\n' "$WEB_HOST" "$WEB_PORT"
printf 'Form emails destination: %s\n' "$ORGANIZER_NEEDS_TO_EMAIL"

export WEB_HOST WEB_PORT SMTP_HOST SMTP_PORT SMTP_USERNAME SMTP_PASSWORD SMTP_FROM ORGANIZER_NEEDS_TO_EMAIL SMTP_TLS

python3 - <<'PY'
import json
import os
import posixpath
import smtplib
from email.message import EmailMessage
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import unquote, urlsplit

HOST = os.environ['WEB_HOST']
PORT = int(os.environ['WEB_PORT'])
DIRECTORY = os.path.join(os.getcwd(), 'build', 'web')

SMTP_HOST = os.environ.get('SMTP_HOST', '').strip()
SMTP_PORT = int(os.environ.get('SMTP_PORT', '587'))
SMTP_USERNAME = os.environ.get('SMTP_USERNAME', '').strip()
SMTP_PASSWORD = os.environ.get('SMTP_PASSWORD', '').strip()
SMTP_FROM = os.environ.get('SMTP_FROM', 'noreply@tikiya.dz').strip()
DEST_EMAIL = os.environ.get('ORGANIZER_NEEDS_TO_EMAIL', 'rayanbenhabiles9@gmail.com').strip()
SMTP_TLS = os.environ.get('SMTP_TLS', '1').strip() in ('1', 'true', 'TRUE', 'yes', 'YES')


class Phase1Handler(SimpleHTTPRequestHandler):
    def _send_json(self, status, payload):
        data = json.dumps(payload).encode('utf-8')
        self.send_response(status)
        self.send_header('Content-Type', 'application/json; charset=utf-8')
        self.send_header('Content-Length', str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_POST(self):
        path = urlsplit(self.path).path
        if path != '/api/orga-needs':
            self._send_json(404, {'message': 'Not Found'})
            return

        try:
            content_length = int(self.headers.get('Content-Length', '0'))
        except ValueError:
            content_length = 0

        if content_length <= 0:
            self._send_json(400, {'message': 'Invalid request body'})
            return

        raw = self.rfile.read(content_length)
        try:
            payload = json.loads(raw.decode('utf-8'))
        except Exception:
            self._send_json(400, {'message': 'Invalid JSON'})
            return

        required = ['first_name', 'last_name', 'email', 'phone', 'instagram']
        missing = [k for k in required if not str(payload.get(k, '')).strip()]
        if missing:
            self._send_json(400, {'message': f'Missing fields: {", ".join(missing)}'})
            return

        if not SMTP_HOST or not SMTP_USERNAME or not SMTP_PASSWORD:
            self._send_json(
                503,
                {'message': 'SMTP not configured (SMTP_HOST/SMTP_USERNAME/SMTP_PASSWORD required)'},
            )
            return

        try:
            msg = EmailMessage()
            msg['Subject'] = f"[Tikiya Pro] Nouveau formulaire organisateur - {payload['first_name']} {payload['last_name']}"
            msg['From'] = SMTP_FROM
            msg['To'] = DEST_EMAIL
            msg['Reply-To'] = payload['email']
            msg.set_content(
                "Nouveau formulaire organisateur\n\n"
                f"Prénom: {payload['first_name']}\n"
                f"Nom: {payload['last_name']}\n"
                f"Email: {payload['email']}\n"
                f"Téléphone: {payload['phone']}\n"
                f"Site/Instagram: {payload['instagram']}\n"
            )

            with smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=20) as smtp:
                smtp.ehlo()
                if SMTP_TLS:
                    smtp.starttls()
                    smtp.ehlo()
                smtp.login(SMTP_USERNAME, SMTP_PASSWORD)
                smtp.send_message(msg)

            self._send_json(200, {'ok': True, 'message': 'Formulaire envoyé'})
        except Exception as e:
            print(f"[phase1-mail] send failed: {e}")
            self._send_json(503, {'message': 'Email service unavailable'})

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


handler = partial(Phase1Handler, directory=DIRECTORY)
with ThreadingHTTPServer((HOST, PORT), handler) as httpd:
    print(f'Serving phase1 build on http://{HOST}:{PORT}/ (root: {DIRECTORY})')
    httpd.serve_forever()
PY

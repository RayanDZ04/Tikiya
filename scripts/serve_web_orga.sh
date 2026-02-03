#!/bin/sh
set -eu
cd "$(dirname "$0")/../App_mobile_organisateur"
flutter pub get
flutter build web --release
python3 -m http.server 3001 --bind 0.0.0.0 --directory build/web

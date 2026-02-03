#!/bin/sh
set -eu
cd "$(dirname "$0")/../App_mobile"
flutter pub get
flutter build web --release
python3 -m http.server 3000 --bind 0.0.0.0 --directory build/web

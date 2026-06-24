#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/app"

BACKEND_BASE_URL="${1:-http://localhost:8000}"
FLUTTER_BIN="${FLUTTER_BIN:-}"

DEFAULT_FIREBASE_API_KEY="AIzaSyBSer1IGO3cE3E3sQD57unqYj9DQOWtmoA"
DEFAULT_FIREBASE_APP_ID="1:778846479860:web:0387dd0c913f29520385a1"
DEFAULT_FIREBASE_MESSAGING_SENDER_ID="778846479860"
DEFAULT_FIREBASE_PROJECT_ID="hidden-solstice-305914"
DEFAULT_FIREBASE_AUTH_DOMAIN="hidden-solstice-305914.firebaseapp.com"
DEFAULT_FIREBASE_STORAGE_BUCKET="hidden-solstice-305914.firebasestorage.app"

if [ -z "$FLUTTER_BIN" ]; then
  if [ -x /opt/flutter/bin/flutter ]; then
    FLUTTER_BIN="/opt/flutter/bin/flutter"
  elif command -v flutter >/dev/null 2>&1; then
    FLUTTER_BIN="$(command -v flutter)"
  fi
fi

if [ -z "$FLUTTER_BIN" ] || [ ! -x "$FLUTTER_BIN" ]; then
  echo "Flutter nao encontrado." >&2
  echo "Instale o Flutter no WSL ou configure FLUTTER_BIN antes de gerar o build." >&2
  exit 1
fi

cd "$APP_DIR"

"$FLUTTER_BIN" pub get

"$FLUTTER_BIN" build web \
  --release \
  --dart-define=NEVIIM_FIREBASE_API_KEY="${NEVIIM_FIREBASE_API_KEY:-$DEFAULT_FIREBASE_API_KEY}" \
  --dart-define=NEVIIM_FIREBASE_APP_ID="${NEVIIM_FIREBASE_APP_ID:-$DEFAULT_FIREBASE_APP_ID}" \
  --dart-define=NEVIIM_FIREBASE_MESSAGING_SENDER_ID="${NEVIIM_FIREBASE_MESSAGING_SENDER_ID:-$DEFAULT_FIREBASE_MESSAGING_SENDER_ID}" \
  --dart-define=NEVIIM_FIREBASE_PROJECT_ID="${NEVIIM_FIREBASE_PROJECT_ID:-$DEFAULT_FIREBASE_PROJECT_ID}" \
  --dart-define=NEVIIM_FIREBASE_AUTH_DOMAIN="${NEVIIM_FIREBASE_AUTH_DOMAIN:-$DEFAULT_FIREBASE_AUTH_DOMAIN}" \
  --dart-define=NEVIIM_FIREBASE_STORAGE_BUCKET="${NEVIIM_FIREBASE_STORAGE_BUCKET:-$DEFAULT_FIREBASE_STORAGE_BUCKET}" \
  --dart-define=NEVIIM_FIREBASE_APP_CHECK_SITE_KEY="${NEVIIM_FIREBASE_APP_CHECK_SITE_KEY:-}" \
  --dart-define=NEVIIM_BACKEND_BASE_URL="${BACKEND_BASE_URL}"

echo "Build web concluido em ${APP_DIR}/build/web"
echo "Backend URL embutida: ${BACKEND_BASE_URL}"

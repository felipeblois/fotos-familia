#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/backend"
APP_DIR="$ROOT_DIR/app"
BACKEND_VENV_DIR="$BACKEND_DIR/.venv-wsl"

BACKEND_PID_FILE="/tmp/neviim_backend.pid"
APP_PID_FILE="/tmp/neviim_flutter.pid"
BACKEND_LOG_FILE="/tmp/neviim_backend.log"
APP_LOG_FILE="/tmp/neviim_flutter.log"

DEFAULT_FIREBASE_API_KEY="AIzaSyBSer1IGO3cE3E3sQD57unqYj9DQOWtmoA"
DEFAULT_FIREBASE_APP_ID="1:778846479860:web:0387dd0c913f29520385a1"
DEFAULT_FIREBASE_MESSAGING_SENDER_ID="778846479860"
DEFAULT_FIREBASE_PROJECT_ID="hidden-solstice-305914"
DEFAULT_FIREBASE_AUTH_DOMAIN="hidden-solstice-305914.firebaseapp.com"
DEFAULT_FIREBASE_STORAGE_BUCKET="hidden-solstice-305914.firebasestorage.app"
DEFAULT_BACKEND_BASE_URL="http://localhost:8000"

ensure_backend_venv() {
  if [ ! -x "$BACKEND_VENV_DIR/bin/python" ]; then
    python3 -m venv "$BACKEND_VENV_DIR"
  fi

  if ! "$BACKEND_VENV_DIR/bin/python" -c "import uvicorn" >/dev/null 2>&1; then
    "$BACKEND_VENV_DIR/bin/pip" install -r "$BACKEND_DIR/requirements.txt"
  fi
}

start_backend() {
  if [ -f "$BACKEND_PID_FILE" ] && kill -0 "$(cat "$BACKEND_PID_FILE")" 2>/dev/null; then
    echo "Backend ja esta em execucao (PID $(cat "$BACKEND_PID_FILE"))."
    return
  fi

  ensure_backend_venv

  if [ ! -f "$BACKEND_DIR/.env" ] && [ -f "$BACKEND_DIR/.env.example" ]; then
    cp "$BACKEND_DIR/.env.example" "$BACKEND_DIR/.env"
  fi

  (
    cd "$BACKEND_DIR"
    nohup "$BACKEND_VENV_DIR/bin/python" -m uvicorn app.main:app --host 0.0.0.0 --port 8000 \
      > "$BACKEND_LOG_FILE" 2>&1 < /dev/null &
    echo $! > "$BACKEND_PID_FILE"
  )

  echo "Backend iniciado em http://localhost:8000 (PID $(cat "$BACKEND_PID_FILE"))."
}

start_app() {
  if ! command -v bash >/dev/null 2>&1 || [ ! -x /opt/flutter/bin/flutter ]; then
    echo "Flutter nao encontrado em /opt/flutter/bin/flutter."
    echo "Instale o Flutter no WSL antes de iniciar o app."
    exit 1
  fi

  if [ -f "$APP_PID_FILE" ] && kill -0 "$(cat "$APP_PID_FILE")" 2>/dev/null; then
    echo "App ja esta em execucao (PID $(cat "$APP_PID_FILE"))."
    return
  fi

  (
    cd "$APP_DIR"
    nohup bash /opt/flutter/bin/flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000 \
      --dart-define=NEVIIM_FIREBASE_API_KEY="${NEVIIM_FIREBASE_API_KEY:-$DEFAULT_FIREBASE_API_KEY}" \
      --dart-define=NEVIIM_FIREBASE_APP_ID="${NEVIIM_FIREBASE_APP_ID:-$DEFAULT_FIREBASE_APP_ID}" \
      --dart-define=NEVIIM_FIREBASE_MESSAGING_SENDER_ID="${NEVIIM_FIREBASE_MESSAGING_SENDER_ID:-$DEFAULT_FIREBASE_MESSAGING_SENDER_ID}" \
      --dart-define=NEVIIM_FIREBASE_PROJECT_ID="${NEVIIM_FIREBASE_PROJECT_ID:-$DEFAULT_FIREBASE_PROJECT_ID}" \
      --dart-define=NEVIIM_FIREBASE_AUTH_DOMAIN="${NEVIIM_FIREBASE_AUTH_DOMAIN:-$DEFAULT_FIREBASE_AUTH_DOMAIN}" \
      --dart-define=NEVIIM_FIREBASE_STORAGE_BUCKET="${NEVIIM_FIREBASE_STORAGE_BUCKET:-$DEFAULT_FIREBASE_STORAGE_BUCKET}" \
      --dart-define=NEVIIM_FIREBASE_APP_CHECK_SITE_KEY="${NEVIIM_FIREBASE_APP_CHECK_SITE_KEY:-}" \
      --dart-define=NEVIIM_BACKEND_BASE_URL="${NEVIIM_BACKEND_BASE_URL:-$DEFAULT_BACKEND_BASE_URL}" \
      > "$APP_LOG_FILE" 2>&1 < /dev/null &
    echo $! > "$APP_PID_FILE"
  )

  echo "App iniciado em http://localhost:3000 (PID $(cat "$APP_PID_FILE"))."
}

start_backend
start_app

echo
echo "Logs:"
echo "  Backend: $BACKEND_LOG_FILE"
echo "  App:     $APP_LOG_FILE"

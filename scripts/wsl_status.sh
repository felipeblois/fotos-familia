#!/usr/bin/env bash
set -euo pipefail

BACKEND_PID_FILE="/tmp/neviim_backend.pid"
APP_PID_FILE="/tmp/neviim_flutter.pid"
BACKEND_LOG_FILE="/tmp/neviim_backend.log"
APP_LOG_FILE="/tmp/neviim_flutter.log"

show_service_status() {
  local name="$1"
  local pid_file="$2"
  local port="$3"
  local url="$4"
  local log_file="$5"

  echo "$name:"
  if [ -f "$pid_file" ]; then
    local pid
    pid="$(cat "$pid_file")"
    if kill -0 "$pid" 2>/dev/null; then
      echo "  Status: running"
      echo "  PID:    $pid"
      echo "  URL:    $url"
    else
      echo "  Status: stale pid file"
      echo "  PID:    $pid"
    fi
  else
    echo "  Status: stopped"
  fi

  if ss -ltnp 2>/dev/null | grep -q ":$port "; then
    echo "  Porta:  $port ouvindo"
  else
    echo "  Porta:  $port fechada"
  fi

  if [ -f "$log_file" ]; then
    echo "  Log:    $log_file"
  fi
}

show_service_status "Backend" "$BACKEND_PID_FILE" "8000" "http://localhost:8000" "$BACKEND_LOG_FILE"
echo
show_service_status "App" "$APP_PID_FILE" "3000" "http://localhost:3000" "$APP_LOG_FILE"

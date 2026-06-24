#!/usr/bin/env bash
set -euo pipefail

BACKEND_PID_FILE="/tmp/neviim_backend.pid"
APP_PID_FILE="/tmp/neviim_flutter.pid"

stop_pid_file() {
  local name="$1"
  local pid_file="$2"

  if [ ! -f "$pid_file" ]; then
    echo "$name nao esta em execucao."
    return
  fi

  local pid
  pid="$(cat "$pid_file")"

  if kill -0 "$pid" 2>/dev/null; then
    kill "$pid"
    echo "$name finalizado (PID $pid)."
  else
    echo "$name ja nao estava ativo."
  fi

  rm -f "$pid_file"
}

stop_pid_file "Backend" "$BACKEND_PID_FILE"
stop_pid_file "App" "$APP_PID_FILE"

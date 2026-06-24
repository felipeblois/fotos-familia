#!/usr/bin/env bash
set -euo pipefail

TARGET="${1:-all}"

show_file() {
  local label="$1"
  local path="$2"
  echo "===== ${label} ====="
  if [[ -f "${path}" ]]; then
    tail -n 100 "${path}"
  else
    echo "Arquivo nao encontrado: ${path}"
  fi
}

case "${TARGET}" in
  api)
    sudo journalctl -u neviim-api -n 100 --no-pager
    ;;
  nginx)
    sudo tail -n 100 /var/log/nginx/neviim-access.log 2>/dev/null || true
    sudo tail -n 100 /var/log/nginx/neviim-error.log 2>/dev/null || true
    ;;
  all)
    sudo journalctl -u neviim-api -n 100 --no-pager || true
    sudo tail -n 50 /var/log/nginx/neviim-access.log 2>/dev/null || true
    sudo tail -n 50 /var/log/nginx/neviim-error.log 2>/dev/null || true
    ;;
  *)
    echo "Uso: scripts/ec2_logs.sh [api|nginx|all]" >&2
    exit 1
    ;;
esac

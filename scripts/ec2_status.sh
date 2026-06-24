#!/usr/bin/env bash
set -euo pipefail

echo "== systemd =="
sudo systemctl status neviim-api --no-pager || true

echo
echo "== portas =="
ss -ltnp | grep -E ":80|:443|:8000" || true

echo
echo "== health local =="
curl -sS http://127.0.0.1:8000/health || true

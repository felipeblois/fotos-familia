#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SYSTEMD_DIR="${PROJECT_ROOT}/deploy/systemd"

echo "Instalando unit systemd do backend..."
sudo cp "${SYSTEMD_DIR}/neviim-api.service" /etc/systemd/system/neviim-api.service

echo "Recarregando systemd..."
sudo systemctl daemon-reload

echo "Habilitando servico..."
sudo systemctl enable neviim-api

echo "Reiniciando servico..."
sudo systemctl restart neviim-api

echo "Status atual:"
sudo systemctl status neviim-api --no-pager || true

#!/usr/bin/env bash
set -euo pipefail

SERVICES=(
  "insightflow-api"
  "insightflow-admin"
)

for service in "${SERVICES[@]}"; do
  if systemctl list-unit-files "${service}.service" >/dev/null 2>&1; then
    echo "Desativando ${service}..."
    sudo systemctl stop "${service}" 2>/dev/null || true
    sudo systemctl disable "${service}" 2>/dev/null || true
  fi
done

echo "Servicos antigos do feedback desativados quando encontrados."

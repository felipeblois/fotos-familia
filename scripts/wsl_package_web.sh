#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="${ROOT_DIR}/app"
BACKEND_BASE_URL="${1:-https://insightflow.ddns.net}"
OUTPUT_PATH="${2:-${ROOT_DIR}/dist/neviim-web.tar.gz}"

"${ROOT_DIR}/scripts/wsl_build_web.sh" "${BACKEND_BASE_URL}"

mkdir -p "$(dirname "${OUTPUT_PATH}")"
tar -czf "${OUTPUT_PATH}" -C "${APP_DIR}/build/web" .

echo "Pacote do frontend gerado em ${OUTPUT_PATH}"
echo "Backend URL embutida: ${BACKEND_BASE_URL}"
echo
echo "Envie para a EC2 com:"
echo "scp ${OUTPUT_PATH} ubuntu@insightflow.ddns.net:/home/ubuntu/neviim-web.tar.gz"

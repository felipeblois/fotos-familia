#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SECRETS_DIR="${PROJECT_ROOT}/secrets"
DEST_PATH="${SECRETS_DIR}/service-account.json"
SOURCE_PATH="${1:-}"

mkdir -p "${SECRETS_DIR}"

if [[ -z "${SOURCE_PATH}" ]]; then
  for candidate in \
    "${PROJECT_ROOT}/service-account.json" \
    "${HOME}/service-account.json" \
    "${HOME}/Downloads/service-account.json"
  do
    if [[ -f "${candidate}" ]]; then
      SOURCE_PATH="${candidate}"
      break
    fi
  done
fi

if [[ -z "${SOURCE_PATH}" || ! -f "${SOURCE_PATH}" ]]; then
  echo "Service account nao encontrada." >&2
  echo "Informe o caminho do arquivo JSON como primeiro argumento." >&2
  echo "Exemplo: scripts/ec2_start_dns_light.sh insightflow.ddns.net /home/ubuntu/service-account.json SEU_ADMIN_UID" >&2
  exit 1
fi

cp "${SOURCE_PATH}" "${DEST_PATH}"
chmod 600 "${DEST_PATH}"

echo "Service account copiada para ${DEST_PATH}."

#!/usr/bin/env bash
set -euo pipefail

WEB_PACKAGE="${1:-}"
WEB_ROOT="${2:-/var/www/neviim}"

if [[ -z "${WEB_PACKAGE}" ]]; then
  echo "Uso: scripts/ec2_publish_frontend.sh <pacote-neviim-web.tar.gz> [web_root]" >&2
  exit 1
fi

if [[ ! -f "${WEB_PACKAGE}" ]]; then
  echo "Pacote do frontend nao encontrado: ${WEB_PACKAGE}" >&2
  echo "Gere no WSL com scripts/wsl_package_web.sh e envie para a EC2." >&2
  exit 1
fi

if [[ "${WEB_ROOT}" != "/var/www/neviim" && "${WEB_ROOT}" != /var/www/neviim/* ]]; then
  echo "WEB_ROOT deve ficar dentro de /var/www/neviim por seguranca." >&2
  exit 1
fi

TMP_DIR="$(mktemp -d)"
cleanup() {
  rm -rf "${TMP_DIR}"
}
trap cleanup EXIT

tar -xzf "${WEB_PACKAGE}" -C "${TMP_DIR}"

if [[ ! -f "${TMP_DIR}/index.html" ]]; then
  echo "Pacote invalido: index.html nao encontrado na raiz do build." >&2
  exit 1
fi

sudo rm -rf "${WEB_ROOT}"
sudo mkdir -p "${WEB_ROOT}"
sudo cp -a "${TMP_DIR}/." "${WEB_ROOT}/"
sudo chown -R www-data:www-data "${WEB_ROOT}"
sudo find "${WEB_ROOT}" -type d -exec chmod 755 {} \;
sudo find "${WEB_ROOT}" -type f -exec chmod 644 {} \;

echo "Frontend publicado em ${WEB_ROOT}."

#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEMPLATE_PATH="${PROJECT_ROOT}/deploy/nginx/neviim.conf.template"
OUTPUT_PATH="/tmp/neviim.nginx.conf"

DOMAIN="${1:-}"
APP_ROOT="${2:-/home/ubuntu/fotos-familia}"
WEB_ROOT="${3:-${APP_ROOT}/app/build/web}"

if [[ -z "${DOMAIN}" ]]; then
  echo "Uso: scripts/ec2_install_nginx.sh <dominio-ou-hostname> [app_root] [web_root]" >&2
  exit 1
fi

sed \
  -e "s|__SERVER_NAME__|${DOMAIN}|g" \
  -e "s|__APP_ROOT__|${APP_ROOT}|g" \
  -e "s|__WEB_ROOT__|${WEB_ROOT}|g" \
  "${TEMPLATE_PATH}" > "${OUTPUT_PATH}"

BACKUP_DIR="/home/ubuntu/nginx-sites-enabled-backup-$(date +%Y%m%d%H%M%S)"
sudo mkdir -p "${BACKUP_DIR}"
sudo cp -a /etc/nginx/sites-enabled/. "${BACKUP_DIR}/" 2>/dev/null || true

sudo cp "${OUTPUT_PATH}" /etc/nginx/sites-available/neviim
sudo ln -sf /etc/nginx/sites-available/neviim /etc/nginx/sites-enabled/neviim
sudo rm -f /etc/nginx/sites-enabled/default
sudo rm -f /etc/nginx/sites-enabled/insightflow
sudo rm -f /etc/nginx/sites-enabled/agente-feedback-conversacional

sudo nginx -t
sudo systemctl reload nginx

find /home/ubuntu -maxdepth 1 -type d -name "nginx-sites-enabled-backup-*" \
  | sort -r \
  | tail -n +4 \
  | xargs -r rm -rf

echo "Nginx configurado para ${DOMAIN}."
echo "Frontend servido de ${WEB_ROOT}."
echo "Backup dos sites habilitados salvo em ${BACKUP_DIR}."

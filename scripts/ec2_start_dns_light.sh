#!/usr/bin/env bash
set -euo pipefail

PUBLIC_HOST="${1:-insightflow.ddns.net}"
SERVICE_ACCOUNT_SOURCE="${2:-}"
ADMIN_UID="${3:-firebase-admin-uid}"
APP_ROOT="${4:-/home/ubuntu/apps/app-neviim}"
PUBLIC_SCHEME="${5:-https}"
WEB_PACKAGE="${6:-/home/ubuntu/neviim-web.tar.gz}"
WEB_ROOT="${7:-/var/www/neviim}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"${SCRIPT_DIR}/ec2_disable_feedback_services.sh"
"${SCRIPT_DIR}/ec2_bootstrap.sh"
"${SCRIPT_DIR}/ec2_write_default_envs.sh" "${PUBLIC_HOST}" "${ADMIN_UID}" "${PUBLIC_SCHEME}"
"${SCRIPT_DIR}/ec2_copy_service_account.sh" "${SERVICE_ACCOUNT_SOURCE}"
"${SCRIPT_DIR}/ec2_setup_backend.sh"
"${SCRIPT_DIR}/ec2_publish_frontend.sh" "${WEB_PACKAGE}" "${WEB_ROOT}"
"${SCRIPT_DIR}/ec2_install_nginx.sh" "${PUBLIC_HOST}" "${APP_ROOT}" "${WEB_ROOT}"
"${SCRIPT_DIR}/ec2_install_systemd.sh"
"${SCRIPT_DIR}/ec2_status.sh"

echo
echo "Neviim preparado em modo leve para acesso em ${PUBLIC_SCHEME}://${PUBLIC_HOST}"
echo "Frontend servido de ${WEB_ROOT}; Flutter nao foi instalado nem compilado na EC2."
if [[ "${ADMIN_UID}" == "firebase-admin-uid" ]]; then
  echo "Painel admin ainda usa UID placeholder. Atualize backend/.env quando souber o UID real."
fi

#!/usr/bin/env bash
set -euo pipefail

PUBLIC_HOST="${1:-98.89.26.27}"
ADMIN_UID="${2:-firebase-admin-uid}"
PUBLIC_SCHEME="${3:-}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_ENV="${PROJECT_ROOT}/backend/.env"
FRONTEND_ENV="${PROJECT_ROOT}/app/.env.ec2"

if [[ -z "${PUBLIC_SCHEME}" ]]; then
  if [[ "${PUBLIC_HOST}" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    PUBLIC_SCHEME="http"
  else
    PUBLIC_SCHEME="https"
  fi
fi

PUBLIC_BASE_URL="${PUBLIC_SCHEME}://${PUBLIC_HOST}"
if [[ "${PUBLIC_SCHEME}" == "https" ]]; then
  ALLOWED_ORIGINS="[\"https://${PUBLIC_HOST}\",\"http://${PUBLIC_HOST}\"]"
else
  ALLOWED_ORIGINS="[\"http://${PUBLIC_HOST}\"]"
fi

cat > "${BACKEND_ENV}" <<EOF
ENVIRONMENT=production
APP_VERSION=0.1.0
APP_PORT=8000
LOG_LEVEL=INFO

EC2_PUBLIC_HOSTNAME=${PUBLIC_HOST}
EC2_PUBLIC_SCHEME=${PUBLIC_SCHEME}

FIREBASE_PROJECT_ID=hidden-solstice-305914
FIREBASE_SERVICE_ACCOUNT_PATH=/home/ubuntu/fotos-familia/secrets/service-account.json
GOOGLE_APPLICATION_CREDENTIALS=/home/ubuntu/fotos-familia/secrets/service-account.json
GCP_PROJECT_ID=hidden-solstice-305914

DRIVE_FOLDER_ID=1WefwWTuE5eSocfY5-KRDSy_Y8-IT9z5l
NEVIIM_MEDIA_CACHE_DIR=/home/ubuntu/fotos-familia/data/media-cache

ADMIN_UID_WHITELIST=["${ADMIN_UID}"]
ALLOWED_ORIGINS=${ALLOWED_ORIGINS}
RATE_LIMIT_PER_MINUTE=60

TERMS_VERSION=1.0.0
LGPD_CONTACT_EMAIL=paroquia@example.com
DPO_NAME=Responsavel pela Paroquia

FCM_SENDER_ID=778846479860
EOF

cat > "${FRONTEND_ENV}" <<EOF
NEVIIM_FIREBASE_API_KEY=AIzaSyBSer1IGO3cE3E3sQD57unqYj9DQOWtmoA
NEVIIM_FIREBASE_APP_ID=1:778846479860:web:0387dd0c913f29520385a1
NEVIIM_FIREBASE_MESSAGING_SENDER_ID=778846479860
NEVIIM_FIREBASE_PROJECT_ID=hidden-solstice-305914
NEVIIM_FIREBASE_AUTH_DOMAIN=hidden-solstice-305914.firebaseapp.com
NEVIIM_FIREBASE_STORAGE_BUCKET=hidden-solstice-305914.firebasestorage.app
NEVIIM_FIREBASE_APP_CHECK_SITE_KEY=
NEVIIM_BACKEND_BASE_URL=${PUBLIC_BASE_URL}
EOF

echo "Arquivos backend/.env e app/.env.ec2 gerados com valores padrao."
echo "Host publico configurado: ${PUBLIC_BASE_URL}"
if [[ "${ADMIN_UID}" == "firebase-admin-uid" ]]; then
  echo "Aviso: substitua ADMIN_UID_WHITELIST pelo UID real do admin Firebase para habilitar o painel admin."
fi

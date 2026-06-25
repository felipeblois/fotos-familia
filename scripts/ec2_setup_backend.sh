#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BACKEND_DIR="${PROJECT_ROOT}/backend"
RUN_DIR="${PROJECT_ROOT}/data/run"
LOG_DIR="${PROJECT_ROOT}/data/logs"
CACHE_DIR="${PROJECT_ROOT}/data/media-cache"
SECRETS_DIR="${PROJECT_ROOT}/secrets"

mkdir -p "${RUN_DIR}" "${LOG_DIR}" "${CACHE_DIR}" "${SECRETS_DIR}"

cd "${BACKEND_DIR}"

if [[ ! -f ".env" ]]; then
  if [[ -f ".env.ec2.example" ]]; then
    echo "Arquivo backend/.env nao encontrado. Criando a partir de backend/.env.ec2.example..."
    cp ".env.ec2.example" ".env"
  else
    echo "Arquivo backend/.env nao encontrado." >&2
    echo "Copie backend/.env.ec2.example para backend/.env e ajuste os valores." >&2
    exit 1
  fi
fi

if [[ ! -f "${SECRETS_DIR}/service-account.json" ]]; then
  echo "Arquivo secrets/service-account.json nao encontrado. Tentando copiar do caminho padrao da EC2..."
  bash "${SCRIPT_DIR}/ec2_copy_service_account.sh"
fi

set_env_value() {
  local key="$1"
  local value="$2"

  if grep -q "^${key}=" ".env"; then
    sed -i "s|^${key}=.*|${key}=${value}|" ".env"
  else
    printf "\n%s=%s\n" "${key}" "${value}" >> ".env"
  fi
}

set_env_value "FIREBASE_SERVICE_ACCOUNT_PATH" "${SECRETS_DIR}/service-account.json"
set_env_value "GOOGLE_APPLICATION_CREDENTIALS" "${SECRETS_DIR}/service-account.json"
set_env_value "NEVIIM_MEDIA_CACHE_DIR" "${CACHE_DIR}"

if [[ ! -d ".venv" ]]; then
  echo "Criando virtualenv do backend..."
  python3 -m venv .venv
fi

source .venv/bin/activate

echo "Atualizando pip..."
pip install --upgrade pip

echo "Instalando dependencias do backend..."
pip install -r requirements.txt

echo "Validando import principal..."
python -c "from app.main import app; print(app.title)"

echo "Setup do backend concluido."

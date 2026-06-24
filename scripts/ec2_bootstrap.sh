#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${BASH_VERSION:-}" ]]; then
  echo "Execute este script em bash na EC2." >&2
  exit 1
fi

echo "Atualizando pacotes da EC2..."
sudo apt update

echo "Instalando dependencias base..."
sudo apt install -y python3 python3-venv python3-pip git nginx curl unzip xz-utils zip libglu1-mesa

echo "Versoes instaladas:"
python3 --version
git --version
nginx -v

echo "Bootstrap da EC2 concluido."

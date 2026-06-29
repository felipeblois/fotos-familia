#!/usr/bin/env bash
set -euo pipefail

APP_ROOT="${1:-/home/ubuntu/fotos-familia}"
WEB_PACKAGE="${2:-/home/ubuntu/neviim-web.tar.gz}"
KEEP_JOURNAL_SIZE="${KEEP_JOURNAL_SIZE:-100M}"

echo "== Uso de disco antes =="
df -h /
echo

echo "== Maiores diretorios em / =="
sudo du -xh --max-depth=1 / 2>/dev/null | sort -h | tail -n 20
echo

echo "== Maiores diretorios em /home/ubuntu =="
sudo du -xh --max-depth=2 /home/ubuntu 2>/dev/null | sort -h | tail -n 30
echo

echo "Removendo pacote web temporario, se existir..."
rm -f "${WEB_PACKAGE}"

echo "Removendo caches Python da aplicacao..."
find "${APP_ROOT}/backend" -type d -name "__pycache__" -prune -exec rm -rf {} + 2>/dev/null || true
rm -rf "${APP_ROOT}/backend/.pytest_cache" 2>/dev/null || true

echo "Removendo caches pip do usuario ubuntu..."
rm -rf /home/ubuntu/.cache/pip 2>/dev/null || true

echo "Mantendo apenas os 3 backups mais recentes de nginx..."
find /home/ubuntu -maxdepth 1 -type d -name "nginx-sites-enabled-backup-*" \
  | sort -r \
  | tail -n +4 \
  | xargs -r rm -rf

echo "Limitando journal do systemd para ${KEEP_JOURNAL_SIZE}..."
sudo journalctl --vacuum-size="${KEEP_JOURNAL_SIZE}" >/dev/null || true

echo "Limpando cache do apt..."
sudo apt clean
sudo apt autoremove -y

echo
echo "== Uso de disco depois =="
df -h /
echo
echo "Limpeza concluida."

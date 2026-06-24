#!/usr/bin/env bash
set -euo pipefail

sudo systemctl restart neviim-api
sudo systemctl reload nginx

echo "Servicos do Neviim reiniciados."

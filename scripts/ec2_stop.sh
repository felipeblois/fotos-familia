#!/usr/bin/env bash
set -euo pipefail

sudo systemctl stop neviim-api || true

echo "Backend do Neviim parado."

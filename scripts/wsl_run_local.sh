#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

"${SCRIPT_DIR}/wsl_stop.sh" || true
"${SCRIPT_DIR}/wsl_start.sh"
echo
"${SCRIPT_DIR}/wsl_status.sh"

#!/usr/bin/env bash
# One-click reproducibility runner.
# Pulls the exact data snapshots deposited on Zenodo (checksummed), then
# builds and runs both pipelines end to end.
set -euo pipefail
cd "$(dirname "$0")"

./fetch_data.sh
docker compose up --build

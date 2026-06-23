#!/usr/bin/env bash
# Phase B: Map CSV -> JSONL -> load MY_TEAM (direct path, no MinIO).
#
#   source ./setup-env.sh
#   ./pipeline/load_my_team.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
PYTHON_IMAGE="python:3.12-slim"

if [[ -z "${SENZING_ENGINE_CONFIGURATION_JSON:-}" ]]; then
  echo "ERROR: Run 'source ./setup-env.sh' first."
  exit 1
fi

echo "=== Phase B: Load MY_TEAM from CSV ==="

echo ""
echo "Step 1: Map CSV -> JSONL"
docker run --rm \
  -e CSV_INPUT="/data/learning/my_team.csv" \
  -e JSONL_OUTPUT="/data/staging/mapped_my_team.jsonl" \
  -e SENZING_DATA_SOURCE="MY_TEAM" \
  -v "${ROOT}:/data" -w /data "$PYTHON_IMAGE" bash -c \
  'pip -q install pandas pyarrow && python learning/map_my_team_csv.py'

echo ""
echo "Step 2: Register data source MY_TEAM"
if ! printf 'listDataSources\nquit\n' | docker run --rm -i -e SENZING_ENGINE_CONFIGURATION_JSON \
  senzing/senzingsdk-tools sz_configtool 2>/dev/null | grep -q MY_TEAM; then
  printf 'addDataSource MY_TEAM\nsave\ny\nquit\n' | docker run --rm -i \
    -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools sz_configtool >/dev/null
fi
echo "MY_TEAM registered."

echo ""
echo "Step 3: Load into Senzing"
docker run --rm -u "$(id -u)" -v "${ROOT}:/data" \
  -e SENZING_ENGINE_CONFIGURATION_JSON \
  senzing/sz-file-loader -f /data/staging/mapped_my_team.jsonl

echo ""
echo "Step 4: Snapshot"
docker run --rm -u "$(id -u)" -v "${ROOT}:/data" -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON \
  senzing/senzingsdk-tools sz_snapshot -QAo truthset_snapshot

echo ""
echo "=== MY_TEAM loaded. Explore: ==="
echo "  get MY_TEAM E001"
echo "  get MY_TEAM E002    # same entity as E001?"
echo "  search jane doe"
echo "  load truthset_snapshot.json && data_source_summary"

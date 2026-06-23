#!/usr/bin/env bash
# Phase B: Map local_clients.csv -> JSONL -> load LOCAL_CLIENTS (direct path, no MinIO).
#
#   source ./setup-env.sh
#   ./pipeline/load_local_clients.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
PYTHON_IMAGE="python:3.12-slim"

if [[ -z "${SENZING_ENGINE_CONFIGURATION_JSON:-}" ]]; then
  echo "ERROR: Run 'source ./setup-env.sh' first."
  exit 1
fi

echo "=== Phase B: Load LOCAL_CLIENTS from CSV ==="

echo ""
echo "Step 1: Map CSV -> JSONL"
docker run --rm \
  -e CSV_INPUT="/data/learning/local_clients.csv" \
  -e JSONL_OUTPUT="/data/staging/mapped_local_clients.jsonl" \
  -e SENZING_DATA_SOURCE="LOCAL_CLIENTS" \
  -v "${ROOT}:/data" -w /data "$PYTHON_IMAGE" bash -c \
  'pip -q install pandas pyarrow && python learning/map_local_clients_csv.py'

echo ""
echo "Step 2: Register data source LOCAL_CLIENTS"
if ! printf 'listDataSources\nquit\n' | docker run --rm -i -e SENZING_ENGINE_CONFIGURATION_JSON \
  senzing/senzingsdk-tools sz_configtool 2>/dev/null | grep -q LOCAL_CLIENTS; then
  printf 'addDataSource LOCAL_CLIENTS\nsave\ny\nquit\n' | docker run --rm -i \
    -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools sz_configtool >/dev/null
fi
echo "LOCAL_CLIENTS registered."

echo ""
echo "Step 3: Load into Senzing"
docker run --rm -u "$(id -u)" -v "${ROOT}:/data" \
  -e SENZING_ENGINE_CONFIGURATION_JSON \
  senzing/sz-file-loader -f /data/staging/mapped_local_clients.jsonl

echo ""
echo "Step 4: Snapshot"
docker run --rm -u "$(id -u)" -v "${ROOT}:/data" -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON \
  senzing/senzingsdk-tools sz_snapshot -QAo truthset_snapshot

echo ""
echo "=== LOCAL_CLIENTS loaded. Explore (see EXPLORER-SESSION.md): ==="
echo "  get LOCAL_CLIENTS CL001"
echo "  get LOCAL_CLIENTS CL002    # same entity as CL001?"
echo "  get LOCAL_CLIENTS CL007 detail"
echo "  get LOCAL_CLIENTS CL008 detail   # related to CL007, not merged?"
echo "  search sarah chen"
echo "  load truthset_snapshot.json && data_source_summary && cross_source_summary"

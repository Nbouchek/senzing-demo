#!/usr/bin/env bash
# Load ALL Parquet datasets from MinIO into Senzing, then snapshot once.
#   source ./setup-env.sh && source ./setup-minio-env.sh
#   ./pipeline/run_all_from_minio.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

register_source() {
  local source="$1"
  if printf 'listDataSources\nquit\n' | docker run --rm -i -e SENZING_ENGINE_CONFIGURATION_JSON \
    senzing/senzingsdk-tools sz_configtool 2>/dev/null | grep -q "\"${source}\""; then
    echo "Data source ${source} already registered."
    return
  fi
  printf "addDataSource %s\nsave\ny\nquit\n" "$source" | docker run --rm -i \
    -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools sz_configtool >/dev/null
  echo "Registered data source: ${source}"
}

echo "=== Register Parquet data sources ==="
register_source "CUSTOMERS_PQ"
register_source "WATCHLIST_PQ"

echo ""
echo "=== Load customers from MinIO ==="
S3_URI=s3://senzing-incoming/customers/ \
SENZING_DATA_SOURCE=CUSTOMERS_PQ \
INCOMING_DIR=customers PARQUET_FILE=customers.parquet \
JSONL_FILE=mapped_customers_pq.jsonl \
SKIP_SNAPSHOT=1 \
./pipeline/run_pipeline.sh

echo ""
echo "=== Load watchlist from MinIO ==="
S3_URI=s3://senzing-incoming/watchlist/ \
SENZING_DATA_SOURCE=WATCHLIST_PQ \
INCOMING_DIR=watchlist PARQUET_FILE=watchlist.parquet \
JSONL_FILE=mapped_watchlist_pq.jsonl \
SKIP_SNAPSHOT=1 \
./pipeline/run_pipeline.sh

echo ""
echo "=== Final snapshot (all sources) ==="
docker run --rm -u "$(id -u)" -v "${ROOT}:/data" -w /data \
  -e SENZING_ENGINE_CONFIGURATION_JSON \
  senzing/senzingsdk-tools sz_snapshot -QAo truthset_snapshot

echo ""
echo "=== All sources loaded. Explore with sz_explorer -> cross_source_summary ==="

#!/usr/bin/env bash
# Local learning exercise: add a NEW dataset (vendors) through MinIO into Senzing.
# No AWS account needed.
#
#   cd ~/Dev/Tutorials/senzing-demo
#   source ./setup-env.sh && source ./setup-minio-env.sh
#   ./pipeline/learn_local_exercise.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ENDPOINT="${AWS_ENDPOINT_URL:-http://localhost:9000}"
PYTHON_IMAGE="python:3.12-slim"

echo "=== Exercise: Load VENDORS_PQ from local MinIO ==="
echo ""

docker compose up -d minio postgres >/dev/null 2>&1 || true

echo "Step 1: Build vendors.parquet from vendors.jsonl"
docker run --rm \
  -e JSONL_INPUT="/data/vendors.jsonl" \
  -e PARQUET_OUTPUT="/data/parquet/vendors.parquet" \
  -v "${ROOT}:/data" -w /data "$PYTHON_IMAGE" bash -c \
  'pip -q install pandas pyarrow && python parquet/jsonl_to_parquet.py'

echo ""
echo "Step 2: Upload to MinIO (local S3)"
export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-minioadmin}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-minioadmin}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
aws --endpoint-url "$ENDPOINT" s3 mb s3://senzing-incoming 2>/dev/null || true
aws --endpoint-url "$ENDPOINT" s3 cp parquet/vendors.parquet \
  s3://senzing-incoming/vendors/vendors.parquet

echo ""
echo "Step 3: Register data source VENDORS_PQ"
if ! printf 'listDataSources\nquit\n' | docker run --rm -i -e SENZING_ENGINE_CONFIGURATION_JSON \
  senzing/senzingsdk-tools sz_configtool 2>/dev/null | grep -q VENDORS_PQ; then
  printf 'addDataSource VENDORS_PQ\nsave\ny\nquit\n' | docker run --rm -i \
    -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools sz_configtool >/dev/null
fi
echo "VENDORS_PQ registered."

echo ""
echo "Step 4: Pipeline — MinIO -> map -> load -> snapshot"
grep -v '^VENDORS_PQ-' staging/.processed_files.log > staging/.processed_files.log.tmp 2>/dev/null || true
mv staging/.processed_files.log.tmp staging/.processed_files.log 2>/dev/null || true

S3_URI=s3://senzing-incoming/vendors/ \
SENZING_DATA_SOURCE=VENDORS_PQ \
INCOMING_DIR=vendors PARQUET_FILE=vendors.parquet \
JSONL_FILE=mapped_vendors_pq.jsonl \
./pipeline/run_pipeline.sh

echo ""
echo "=== Exercise complete ==="
echo ""
echo "Explore (inside container):"
echo "  docker run --rm -it -v \${PWD}:/data -w /data -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools"
echo "  sz_explorer"
echo "  load truthset_snapshot.json"
echo "  cross_source_summary          # look for VENDORS_PQ rows"
echo "  search maria sentosa          # V003 may match existing watchlist entity"
echo "  get VENDORS_PQ V001"
echo "  get VENDORS_PQ V002           # V001+V002 should be same org (duplicate vendors)"

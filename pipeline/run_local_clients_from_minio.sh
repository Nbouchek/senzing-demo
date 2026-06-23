#!/usr/bin/env bash
# Phase C: CSV -> Parquet -> MinIO -> map -> load LOCAL_CLIENTS_PQ.
# Simulates a production S3 drop using local MinIO (no AWS account).
#
#   source ./setup-env.sh && source ./setup-minio-env.sh
#   ./pipeline/run_local_clients_from_minio.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ENDPOINT="${AWS_ENDPOINT_URL:-http://localhost:9000}"
PYTHON_IMAGE="python:3.12-slim"

echo "=== Phase C: LOCAL_CLIENTS_PQ via MinIO ==="

docker compose up -d minio postgres >/dev/null 2>&1 || true

echo ""
echo "Step 1: CSV -> Parquet"
docker run --rm \
  -e CSV_INPUT="/data/learning/local_clients.csv" \
  -e PARQUET_OUTPUT="/data/parquet/local_clients.parquet" \
  -v "${ROOT}:/data" -w /data "$PYTHON_IMAGE" bash -c \
  'pip -q install pandas pyarrow && python learning/csv_to_parquet.py'

echo ""
echo "Step 2: Upload to MinIO"
export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-minioadmin}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-minioadmin}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
aws --endpoint-url "$ENDPOINT" s3 mb s3://senzing-incoming 2>/dev/null || true
aws --endpoint-url "$ENDPOINT" s3 cp parquet/local_clients.parquet \
  s3://senzing-incoming/local_clients/local_clients.parquet

echo ""
echo "Step 3: Register LOCAL_CLIENTS_PQ"
if ! printf 'listDataSources\nquit\n' | docker run --rm -i -e SENZING_ENGINE_CONFIGURATION_JSON \
  senzing/senzingsdk-tools sz_configtool 2>/dev/null | grep -q LOCAL_CLIENTS_PQ; then
  printf 'addDataSource LOCAL_CLIENTS_PQ\nsave\ny\nquit\n' | docker run --rm -i \
    -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools sz_configtool >/dev/null
fi

echo ""
echo "Step 4: Pipeline (MinIO -> map -> load -> snapshot)"
grep -v '^LOCAL_CLIENTS_PQ-' staging/.processed_files.log > staging/.tmp 2>/dev/null || true
mv staging/.tmp staging/.processed_files.log 2>/dev/null || true

S3_URI=s3://senzing-incoming/local_clients/ \
SENZING_DATA_SOURCE=LOCAL_CLIENTS_PQ \
INCOMING_DIR=local_clients PARQUET_FILE=local_clients.parquet \
JSONL_FILE=mapped_local_clients_pq.jsonl \
./pipeline/run_local_clients_pipeline.sh

echo ""
echo "=== Phase C complete ==="
echo "Compare Phase B vs Phase C:"
echo "  get LOCAL_CLIENTS CL001"
echo "  get LOCAL_CLIENTS_PQ CL001"
echo "MinIO console: http://localhost:9001 (minioadmin / minioadmin)"

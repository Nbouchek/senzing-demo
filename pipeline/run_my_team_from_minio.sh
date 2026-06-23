#!/usr/bin/env bash
# Phase C: CSV -> Parquet -> MinIO -> map -> load MY_TEAM_PQ.
# Simulates a production S3 drop using local MinIO (no AWS account).
#
#   source ./setup-env.sh && source ./setup-minio-env.sh
#   ./pipeline/run_my_team_from_minio.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ENDPOINT="${AWS_ENDPOINT_URL:-http://localhost:9000}"
PYTHON_IMAGE="python:3.12-slim"

echo "=== Phase C: MY_TEAM_PQ via MinIO ==="

docker compose up -d minio postgres >/dev/null 2>&1 || true

echo ""
echo "Step 1: CSV -> Parquet"
docker run --rm \
  -e CSV_INPUT="/data/learning/my_team.csv" \
  -e PARQUET_OUTPUT="/data/parquet/my_team.parquet" \
  -v "${ROOT}:/data" -w /data "$PYTHON_IMAGE" bash -c \
  'pip -q install pandas pyarrow && python learning/csv_to_parquet.py'

echo ""
echo "Step 2: Upload to MinIO"
export AWS_ACCESS_KEY_ID="${AWS_ACCESS_KEY_ID:-minioadmin}"
export AWS_SECRET_ACCESS_KEY="${AWS_SECRET_ACCESS_KEY:-minioadmin}"
export AWS_DEFAULT_REGION="${AWS_DEFAULT_REGION:-us-east-1}"
aws --endpoint-url "$ENDPOINT" s3 mb s3://senzing-incoming 2>/dev/null || true
aws --endpoint-url "$ENDPOINT" s3 cp parquet/my_team.parquet \
  s3://senzing-incoming/my_team/my_team.parquet

echo ""
echo "Step 3: Register MY_TEAM_PQ"
if ! printf 'listDataSources\nquit\n' | docker run --rm -i -e SENZING_ENGINE_CONFIGURATION_JSON \
  senzing/senzingsdk-tools sz_configtool 2>/dev/null | grep -q MY_TEAM_PQ; then
  printf 'addDataSource MY_TEAM_PQ\nsave\ny\nquit\n' | docker run --rm -i \
    -e SENZING_ENGINE_CONFIGURATION_JSON senzing/senzingsdk-tools sz_configtool >/dev/null
fi

echo ""
echo "Step 4: Pipeline (MinIO -> map -> load -> snapshot)"
# Custom mapper for my_team Parquet columns
grep -v '^MY_TEAM_PQ-' staging/.processed_files.log > staging/.tmp 2>/dev/null || true
mv staging/.tmp staging/.processed_files.log 2>/dev/null || true

S3_URI=s3://senzing-incoming/my_team/ \
SENZING_DATA_SOURCE=MY_TEAM_PQ \
INCOMING_DIR=my_team PARQUET_FILE=my_team.parquet \
JSONL_FILE=mapped_my_team_pq.jsonl \
./pipeline/run_my_team_pipeline.sh

echo ""
echo "=== Phase C complete ==="

#!/usr/bin/env bash
# One-time MinIO setup: start server, create bucket, upload sample Parquet files.
#   cd ~/Dev/Tutorials/senzing-demo
#   ./pipeline/setup_minio.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

BUCKET="senzing-incoming"
ENDPOINT="http://localhost:9000"
PYTHON_IMAGE="python:3.12-slim"

build_parquet() {
  local jsonl="$1"
  local output="$2"
  docker run --rm \
    -e JSONL_INPUT="/data/${jsonl}" \
    -e PARQUET_OUTPUT="/data/${output}" \
    -v "${ROOT}:/data" -w /data "$PYTHON_IMAGE" bash -c \
    'pip -q install pandas pyarrow && python parquet/jsonl_to_parquet.py'
}

echo "=== Step A: Start MinIO (local S3) ==="
docker compose up -d minio postgres

echo "Waiting for MinIO..."
for i in $(seq 1 30); do
  if curl -sf "${ENDPOINT}/minio/health/live" >/dev/null 2>&1; then
    echo "MinIO is ready."
    break
  fi
  [[ "$i" -eq 30 ]] && { echo "ERROR: MinIO timeout"; exit 1; }
  sleep 2
done

if ! command -v aws &>/dev/null; then
  echo "Install AWS CLI: brew install awscli"
  exit 1
fi

export AWS_ACCESS_KEY_ID=minioadmin
export AWS_SECRET_ACCESS_KEY=minioadmin
export AWS_DEFAULT_REGION=us-east-1

echo ""
echo "=== Step B: Create bucket s3://${BUCKET} ==="
aws --endpoint-url "$ENDPOINT" s3 mb "s3://${BUCKET}" 2>/dev/null || true

echo ""
echo "=== Step C: Build Parquet files from JSONL ==="
mkdir -p parquet
build_parquet "customers.jsonl" "parquet/customers.parquet"
build_parquet "watchlist.jsonl" "parquet/watchlist.parquet"

echo ""
echo "=== Step D: Upload to MinIO ==="
aws --endpoint-url "$ENDPOINT" s3 cp parquet/customers.parquet \
  "s3://${BUCKET}/customers/customers.parquet"
aws --endpoint-url "$ENDPOINT" s3 cp parquet/watchlist.parquet \
  "s3://${BUCKET}/watchlist/watchlist.parquet"

echo ""
echo "=== Step E: Verify ==="
aws --endpoint-url "$ENDPOINT" s3 ls "s3://${BUCKET}/" --recursive

echo ""
echo "=== MinIO setup complete ==="
echo "Console: http://localhost:9001  (minioadmin / minioadmin)"
echo ""
echo "Next:"
echo "  source ./setup-env.sh"
echo "  source ./setup-minio-env.sh"
echo "  ./pipeline/run_all_from_minio.sh"

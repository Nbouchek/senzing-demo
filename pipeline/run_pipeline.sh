#!/usr/bin/env bash
# Orchestrate one dataset: S3/MinIO Parquet -> map -> load -> (optional) snapshot
#
# Examples (after source ./setup-env.sh):
#   source ./setup-minio-env.sh
#   ./pipeline/run_pipeline.sh
#
#   S3_URI=s3://senzing-incoming/watchlist/ \
#   SENZING_DATA_SOURCE=WATCHLIST_PQ \
#   INCOMING_DIR=watchlist PARQUET_FILE=watchlist.parquet \
#   JSONL_FILE=mapped_watchlist_pq.jsonl \
#   ./pipeline/run_pipeline.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ -z "${SENZING_ENGINE_CONFIGURATION_JSON:-}" ]]; then
  echo "ERROR: Run 'source ./setup-env.sh' first."
  exit 1
fi

S3_URI="${S3_URI:-}"
INCOMING_DIR="${INCOMING_DIR:-customers}"
PARQUET_FILE="${PARQUET_FILE:-customers.parquet}"
JSONL_FILE="${JSONL_FILE:-mapped_customers_pq.jsonl}"
DATA_SOURCE="${SENZING_DATA_SOURCE:-CUSTOMERS_PQ}"
SKIP_SNAPSHOT="${SKIP_SNAPSHOT:-0}"
PYTHON_IMAGE="python:3.12-slim"

INCOMING="${ROOT}/incoming/${INCOMING_DIR}"
STAGING="${ROOT}/staging"
PROCESSED_LOG="${ROOT}/staging/.processed_files.log"
PARQUET_PATH="${INCOMING}/${PARQUET_FILE}"
JSONL_PATH="${STAGING}/${JSONL_FILE}"

mkdir -p "$INCOMING" "$STAGING"

echo "=== Pipeline: ${DATA_SOURCE} ==="
echo "=== Step 1: Acquire Parquet files ==="
if [[ -n "$S3_URI" ]]; then
  if ! command -v aws &>/dev/null; then
    echo "ERROR: aws CLI not found. Install with: brew install awscli"
    exit 1
  fi
  AWS_ARGS=()
  if [[ -n "${AWS_ENDPOINT_URL:-}" ]]; then
    AWS_ARGS+=(--endpoint-url "$AWS_ENDPOINT_URL")
    echo "Using S3 endpoint: $AWS_ENDPOINT_URL"
  fi
  rm -rf "${INCOMING:?}"/*
  mkdir -p "$INCOMING"
  echo "Syncing from $S3_URI -> $INCOMING"
  aws s3 sync "$S3_URI" "$INCOMING" "${AWS_ARGS[@]}" --exclude "*" --include "*.parquet"
else
  echo "No S3_URI — using local folder: $INCOMING"
  if [[ ! -f "$PARQUET_PATH" ]]; then
    echo "Building sample Parquet from customers.jsonl..."
    docker run --rm \
      -e JSONL_INPUT="/data/customers.jsonl" \
      -e PARQUET_OUTPUT="/data/incoming/${INCOMING_DIR}/${PARQUET_FILE}" \
      -v "${ROOT}:/data" -w /data "$PYTHON_IMAGE" bash -c \
      'pip -q install pandas pyarrow && python parquet/jsonl_to_parquet.py'
  fi
fi

if [[ ! -f "$PARQUET_PATH" ]]; then
  echo "ERROR: Expected Parquet file: $PARQUET_PATH"
  exit 1
fi

FILE_KEY="${DATA_SOURCE}-${PARQUET_FILE}-$(stat -f %m "$PARQUET_PATH" 2>/dev/null || stat -c %Y "$PARQUET_PATH")"
if [[ -f "$PROCESSED_LOG" ]] && grep -q "^${FILE_KEY}$" "$PROCESSED_LOG"; then
  echo "Already processed ${DATA_SOURCE} — remove line '${FILE_KEY}' from $PROCESSED_LOG to reload."
  exit 0
fi

echo ""
echo "=== Step 2: Map Parquet -> Senzing JSONL ==="
docker run --rm \
  -e PARQUET_INPUT="/data/incoming/${INCOMING_DIR}/${PARQUET_FILE}" \
  -e JSONL_OUTPUT="/data/staging/${JSONL_FILE}" \
  -e SENZING_DATA_SOURCE="$DATA_SOURCE" \
  -v "${ROOT}:/data" -w /data "$PYTHON_IMAGE" bash -c \
  'pip -q install pandas pyarrow && python pipeline/map_parquet_to_jsonl.py'

echo ""
echo "=== Step 3: Load into Senzing ==="
docker run --rm -u "$(id -u)" -v "${ROOT}:/data" \
  -e SENZING_ENGINE_CONFIGURATION_JSON \
  senzing/sz-file-loader -f "/data/staging/${JSONL_FILE}"

if [[ "$SKIP_SNAPSHOT" != "1" ]]; then
  echo ""
  echo "=== Step 4: Snapshot for EDA reports ==="
  docker run --rm -u "$(id -u)" -v "${ROOT}:/data" -w /data \
    -e SENZING_ENGINE_CONFIGURATION_JSON \
    senzing/senzingsdk-tools sz_snapshot -QAo truthset_snapshot
fi

echo "$FILE_KEY" >> "$PROCESSED_LOG"
echo ""
echo "=== Done: ${DATA_SOURCE} ==="
